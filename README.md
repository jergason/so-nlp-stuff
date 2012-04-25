#Notes
This is a set of scripts and data for doing NLP on StackOverflow.com.
It uses Ruby, and Python for the script ripped from StackOverflow.

## Installation and Dependencies
You need a working installation of Ruby, and a working installation of bundler.
See the [Ruby website](http://www.ruby-lang.org/en/) for info on installing Ruby.

Once Ruby is installed, install Bundler:

    gem install bundler

Then install the required dependencies:

    bundle install

You also need a working Python installation, with the [BeautifulSoup4](http://www.crummy.com/software/BeautifulSoup/).
package installed. If you have `pip`, you can install it with:

    pip install beautifulsoup4

That should set you up with everything you need to run the scripts.

##Workflow for getting tagged data
1. Run `bundle install` to make sure you have all dependencies
1. Modify `main.rb` to change the parameters of users who will be downloaded
1. Run `main.rb` to download users. Note that this may time out or die if you hit the request limit.
1. Run the `get_tags_for_questions.rb` script to add tags to questions and answers.

Now the data is imported and in a format that the python import script is happy with.

##Workflow for creating a tag inference model
1. Download tagged data (see workflow for getting tagged data)
1. Run `stack_overflow.py` to process the data into a format ready for mallet
1. Run mallet on the data, making sure to save the inference model somewhere.
1. Run the `get_label_topics.rb` file to generate the inference model.

##Workflow for testing tag inference

1. Create a tag inference model (see previous instructions)
1. take a subset of users questions. I used a subset of questions from the `middle_users` group.
1. Process them in to a directory using the python `stack_overflow.py` import script
1. Run the `evaluate_tag_inference.rb` script.
