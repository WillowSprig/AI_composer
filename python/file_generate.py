from textgenrnn import textgenrnn

#textgen = textgenrnn()

def generate_file(textgen, files):
    textgen.train_on_texts(files, num_epochs=1)

    output = textgen.generate(n=30, temperature=[0.3], return_as_list=True)

    with open('ai.ly','w') as file:
        for line in output:
            file.write(line+'\n')
