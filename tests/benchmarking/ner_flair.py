
import os
import argparse
import zipfile
from datetime import datetime
from flair.data import Corpus
from flair.datasets import WNUT_17
from flair.embeddings import TokenEmbeddings, WordEmbeddings, StackedEmbeddings, FlairEmbeddings
from typing import List
from tensorflow.python.lib.io import file_io


def upload_results(args):
    def zipdir(path, fname):
        zipf = zipfile.ZipFile(fname, 'w', zipfile.ZIP_DEFLATED)
        # ziph is zipfile handle
        for root, dirs, files in os.walk(path):
            for file in files:
                zipf.write(os.path.join(root, file))
        zipf.close()

    if args.results_url:
        print('compressing results...', end='')
        base_folder = os.path.split(args.job_dir)[0]
        task_folder = os.path.split(args.job_dir)[1]
        fname = 'results_{}_{}.zip'.format(task_folder, datetime.now().strftime("%Y%m%d%H%M%S"))
        file_path = os.path.join(base_folder, fname)
        zipdir(args.job_dir, file_path)
        print('[OK]')
        print('copying files to gcs...', end='')
        with file_io.FileIO(file_path, mode='rb') as input_f:
            with file_io.FileIO(os.path.join(args.results_url, fname), mode='wb') as output_f:
                output_f.write(input_f.read())
        print('[OK]')

def run(args):
    # 1. get the corpus
    corpus: Corpus = WNUT_17()

    # 2. what tag do we want to predict?
    tag_type = 'ner'

    # 3. make the tag dictionary from the corpus
    tag_dictionary = corpus.make_tag_dictionary(tag_type=tag_type)

    # initialize embeddings
    embedding_types: List[TokenEmbeddings] = [
        WordEmbeddings('crawl'),
        WordEmbeddings('twitter'),
        FlairEmbeddings('news-forward'),
        FlairEmbeddings('news-backward'),
    ]

    embeddings: StackedEmbeddings = StackedEmbeddings(embeddings=embedding_types)

    # initialize sequence tagger
    from flair.models import SequenceTagger

    tagger: SequenceTagger = SequenceTagger(hidden_size=256,
                                            embeddings=embeddings,
                                            tag_dictionary=tag_dictionary,
                                            tag_type=tag_type)

    # initialize trainer
    from flair.trainers import ModelTrainer

    trainer: ModelTrainer = ModelTrainer(tagger, corpus, use_tensorboard=True)

    trainer.train(
        args.job_dir,
        train_with_dev=True,
        max_epochs=args.epochs
    )

    upload_results(args)



if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('--epochs', type=int, default=1)
    parser.add_argument('--job-dir')
    parser.add_argument('--results-url')
    parser.add_argument('--reuse', action='store_true')
    args = parser.parse_args()
    run(args)