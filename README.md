#Notes

Better late then never.

##Workflow for getting tagged data
1. Run `bundle install` to make sure you have all dependencies
1. Modify `main.rb` to change the parameters of users who will be downloaded`
1. Run `main.rb` to download users. Note that this may time out or die if you use up the request limit.
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
