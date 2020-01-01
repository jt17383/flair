


FROM pytorch/pytorch

WORKDIR /root
RUN pip install flair tensorflow
#COPY dist/tabsabertpair-0.0.1-py3-none-any.whl tabsabertpair-0.0.1-py3-none-any.whl
COPY tests/benchmarking/ner_flair.py ner/ner_flair.py
ADD gcloud/iglesiaebg.json gcloud/iglesiaebg.json
ADD Makefile Makefile
#RUN pip install tabsabertpair-0.0.1-py3-none-any.whl -t .
ENV GOOGLE_APPLICATION_CREDENTIALS=gcloud/iglesiaebg.json

# RUN pip install tensorflow google-cloud-storage gym keras sklearn
# #WORKDIR /root
# RUN mkdir -p xdrl/nchain
# COPY agents xdrl/nchain
# COPY gcloud_auth.json xdrl
# RUN echo 'export GOOGLE_APPLICATION_CREDENTIALS="gcloud_auth.json"' >> .bashrc
# WORKDIR /root/xdrl

# # Set up the entry point to invoke the trainer.
ENTRYPOINT ["python", "-m", "ner.ner_flair"]