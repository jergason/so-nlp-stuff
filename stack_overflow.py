# Script to parse stack overflow data into a form mallet likes

import codecs
import os
import json
import sys
from bs4 import BeautifulSoup

def _extract(data_dir, result_dir):
    print('getting stack overflow data! woot woot')
    metadata = {}
    counter = 0
    user_dirs = os.walk(data_dir).next()[1]
    progress_counter = 0
    for user in user_dirs:
        if user == '.':
            continue
        counter, question_metadata = _clean_questions_and_answers(os.path.join(data_dir, user), 'questions', result_dir, counter, user)
        counter, answer_metadata = _clean_questions_and_answers(os.path.join(data_dir, user), 'answers', result_dir, counter, user)
        metadata.update(question_metadata)
        metadata.update(answer_metadata)
        progress_counter += 1
        print('Done with extracting stuff for user %d of %d' % (progress_counter, len(user_dirs)))
    sys.stderr.write("DONE WITH SOME STUFFFFFFFFF!")
    #_write_out_metadata(metadata, result_dir)

def _extract_combined(data_dir, result_dir):
    print('getting stack overflow data! woot woot')
    user_dirs = os.walk(data_dir).next()[1]
    progress_counter = 0
    for user in user_dirs:
        if user == '.':
            continue
        _clean_qa_single_file(os.path.join(data_dir, user), result_dir, user)
        progress_counter += 1
        print('Done with extracting stuff for user %d of %d' % (progress_counter, len(user_dirs)))
    sys.stderr.write("DONE WITH SOME STUFFFFFFFFF!")

def extract_questions_only(data_dir, result_dir):
    print('getting stack overflow data! woot woot')
    counter = 0
    user_dirs = os.walk(data_dir).next()[1]
    print user_dirs
    progress_counter = 0
    for user in user_dirs:
        if user == '.':
            continue
        counter, question_metadata = _clean_questions_and_answers(os.path.join(data_dir, user), 'questions', result_dir, counter, user)
        progress_counter += 1
        print('Done with extracting stuff for user %d of %d' % (progress_counter, len(user_dirs)))
    sys.stderr.write("DONE WITH SOME STUFFFFFFFFF!")

def _get_metadata_for_document(document):
    """Given a dictionary, will pull the relevant metadata out of it and return it as a dictionary."""
    data = {
        'author_name': document['owner']['display_name'],
        'user_id': document['owner']['user_id'],
        'title': document['title'],
        'timestamp': document['last_activity_date']
     }
    if 'answer_id' in document.keys():
        data['question_or_answer'] = 'answer'
        data['id'] = document['answer_id']
    else:
        data['question_or_answer'] = 'question'
        data['id'] = document['question_id']
    return data

def _write_out_metadata(metadata, output_dir):
    formatted_data = {
        'types': {
            'author_name': 'text',
            'user_id': 'int',
            'title': 'text',
            'question_or_answer': 'text',
            'id': 'int',
            'timestamp': 'int'
        },
        'data': metadata
    }
    w = create_dirs_and_open(os.path.join(output_dir, '..', 'metadata', 'documents.json'))
    w.write(json.dumps(formatted_data))
    w.close()

def _clean_questions_and_answers(base_dir, q_or_a, output_dir, counter, user_id):
    metadata = {}
    with open(os.path.join(base_dir, 'raw', '%s.json' % q_or_a)) as f:
        raw = f.read()
    dat = json.loads(raw)
    for item in dat:
        metadata['%s.txt' % counter] = _get_metadata_for_document(item)
        soup = BeautifulSoup(item['body'])
        if q_or_a == 'questions':
            item_id = item['question_id']
        else:
            item_id = item['answer_id']
        w = create_dirs_and_open(os.path.join(output_dir, '%s-%s-%s.txt' % (user_id, q_or_a, item_id)))
        w.write(soup.get_text())
        w.close()
        counter += 1

    return counter, metadata

def _clean_qa_single_file(base_dir, output_dir, user_id):
    with open(os.path.join(base_dir, 'raw', 'questions.json')) as f:
        raw_questions = f.read()
    questions = json.loads(raw_questions)

    with open(os.path.join(base_dir, 'raw', 'answers.json')) as f:
        raw_answers = f.read()
    answers = json.loads(raw_answers)

    results = ''.join([BeautifulSoup(item['body']).get_text() for item in questions])
    results += ''.join([BeautifulSoup(item['body']).get_text() for item in answers])

    w = create_dirs_and_open(os.path.join(output_dir, '%s.txt' % str(user_id)))
    w.write(results)
    w.close()

def create_dirs_and_open(filename):
    """This assumes that you want to open the file for writing.  It doesn't
    make much sense to create directories if you are not going to open for
    writing."""
    try:
        return codecs.open(filename, 'w', 'utf-8')
    except IOError as e:
        import errno
        if e.errno != errno.ENOENT:
            raise
    directory = filename.rsplit('/', 1)[0]
    _try_makedirs(directory)
    return open(filename, 'w')

def _try_makedirs(path):
    """Do the equivalent of mkdir -p."""
    try:
        os.makedirs(path)
    except OSError, e:
        import errno
        if e.errno != errno.EEXIST:
            raise


if (__name__ == "__main__"):
    if len(sys.argv) < 3:
        print("Usage: python stack_overflow.py <input-dir> <output-dir>")
        print("or")
        print("python stack_overflow.py questions <input-dir> <output-dir>")
    else:
        if len(sys.argv) == 4:
            extract_questions_only(sys.argv[2], sys.argv[3])
        else:
            _extract(sys.argv[1], sys.argv[2])
