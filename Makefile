
IMAGE_REPO_NAME=pytorch
IMAGE_REPO_TAG=ner
PROJECT_ID=jtresearch
IMAGE_URI=gcr.io/${PROJECT_ID}/${IMAGE_REPO_NAME}:${IMAGE_REPO_TAG}

#DATA_DIR=~/data/tabsa

builddocker:
	echo "building wheel..."
	python setup.py sdist bdist_wheel
	echo "building docker..."
	docker build -f Dockerfile -t ${IMAGE_URI} .

runlocal:
	export GOOGLE_APPLICATION_CREDENTIALS=gcloud/iglesiaebg.json
	python -m ner_flair \
	  --job-dir=runs/wnut \
    --results-url=gs://jtresearchbucket/ner

rundocker:
  docker run -it --entrypoint /bin/bash ${IMAGE_URI}
  #docker run $IMAGE_URI --job-dir=runs/wnut --results-url=gs://jtresearchbucket/ner

configcloud:
	#!/usr/bin/env bash

	# GOOGLE CLOUD AUTHENTICATION
	# install gcloud sdk https://cloud.google.com/sdk/docs/quickstart-macos
	gcloud auth list
	#gcloud auth login `ACCOUNT`
	gcloud auth login iglesiaebg
	# OR to change the current active account
	#gcloud config set account `ACCOUNT`
	gcloud config set account iglesiaebg

	# GOOGLE CLOUD PROJECT
	gcloud projects list
	#gcloud config set project `PROJECT_NAME`
	gcloud config set project jtresearch

	# GOOGLE CLOUD TO RUN ML ENGINE
	# to be able to run in google cloud, we need to configure authentication
	# create user
	#gcloud iam service-accounts create [ACCOUNT_NAME]
	gcloud iam service-accounts create jtresearcher
	#assign role
	#gcloud projects add-iam-policy-binding [PROJECT_ID] --member "serviceAccount:[ACCOUNT_NAME]@[PROJECT_ID].iam.gserviceaccount.com" --role "roles/owner"
	gcloud projects add-iam-policy-binding jtresearch --member "serviceAccount:jtresearcher@jtresearch.iam.gserviceaccount.com" --role "roles/owner"
	#get key
	gcloud iam service-accounts keys create gcloud/jtresearcher.json --iam-account jtresearcher@jtresearch.iam.gserviceaccount.com
	#export GOOGLE_APPLICATION_CREDENTIALS="[FILENAME].json"

# REGION: select a region from https://cloud.google.com/ml-engine/docs/regions
# or use the default '`us-central1. The region is where the model will be deployed.
REGION="us-central1" #us-east1 #
TIER="BASIC_GPU" # BASIC | BASIC_GPU | STANDARD_1 | PREMIUM_1
PROJECT_ID="jtresearch"
BUCKET="jtresearchbucket"
MODEL_NAME="flairner"
DATASET="wnut"
MODEL_DIR="gs://${BUCKET}/ner"
PACKAGE_PATH=ner # this can be a gcs location to a zipped and uploaded package
CURRENT_DATE=`date +%Y%m%d_%H%M%S`
# JOB_NAME: the name of your job running on Cloud ML Engine.
JOB_NAME=${MODEL_NAME}_${DATASET}_${TIER}_${CURRENT_DATE}


#rungcloudstandard:
#	################################################
#	# USING STANDARD GOOGLE ML ENGINE:
#	################################################
#
#	echo "Model: ${JOB_NAME}"
#
#	#gcloud ai-platform local train \
#	#        --job-dir=~/data/xdrl/${DATASET}_${MODEL_NAME} \
#	#        --module-name=agents.ntext_agent \
#	#        --package-path=${PACKAGE_PATH}  \
#	#        -- \
#
#	gcloud ai-platform jobs submit training ${JOB_NAME} \
#			--stream-logs \
#			--job-dir=${MODEL_DIR} \
#			--runtime-version=1.13 \
#			--python-version 3.5 \
#			--region=${REGION} \
#			--module-name=agents.ntext_agent \
#			--package-path=${PACKAGE_PATH}  \
#			--packages ./env/dist/gym-ntext-env-0.0.4.tar.gz \
#			--config=config.yaml \
#			-- \
#			--model=rl-deepq \
#			--rep-model=fasttext \
#			--max-episode-steps=25000 \
#			--num-episodes=50 \
#			--num-experiments=5
#
rungcloudcustom:
  # echo "hey"
	# USING CUSTOM CONTAINER FOR GOOGLE ML ENGINE

  gcloud auth configure-docker

	docker push $IMAGE_URI
	#
	#
	#export JOB_NAME=ner_flair_${DATASET}_${MODEL_NAME}_${TIER}_${CURRENT_DATE}
	echo "Model: ${JOB_NAME}"
	MODEL_DIR="results/wnut/flair"

	gcloud beta ml-engine jobs submit training $JOB_NAME \
	    --stream-logs \
	    --region $REGION \
	    --master-image-uri $IMAGE_URI \
	    --scale-tier $TIER \
	    -- \
	    --job-dir=$MODEL_DIR \
	    --results-url=gs://jtresearchbucket/ner \
	    --epochs=150
