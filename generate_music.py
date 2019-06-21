
##from keras.preprocessing import sequence as ksequence
import keras.layers as klayers
from keras.models import Sequential as Seq_model
from keras.utils import to_categorical
import numpy as np

def create_network(data):

    dataset_size = 255
    batch_size = 20
    num_steps = 10
    hidden_size = 100
    ##reversed_dictionary = dict(zip(data.values(), data.keys()))

    model = Seq_model()
    model.add(klayers.Embedding(dataset_size, hidden_size, input_length=num_steps))
    model.add(klayers.LSTM(hidden_size, return_sequences=True))
    model.add(klayers.LSTM(hidden_size, return_sequences=True))
    ##if use_dropout:
    model.add(klayers.Dropout(0.5))
    model.add(klayers.TimeDistributed(klayers.Dense(dataset_size)))
    model.add(klayers.Activation('softmax'))

    model.compile(loss='categorical_crossentropy', optimizer='adam', metrics=['categorical_accuracy'])
    
    data_generator = KerasBatchGenerator(data, num_steps, batch_size, dataset_size, skip_step=num_steps)
    
    return data_generator, model##, reversed_dictionary


def run_network(generator, model, iterations, num_steps, dataset):
    ret_value = ''
    for i in range(iterations):
        data = next(generator.generate())
        prediction = model.predict(data[0])
        ##num_steps = len(prediction)
        
        predict_word = np.argmax(prediction[:, num_steps-1, :])
        ret_value += dataset[predict_word] + " "
    print([i, ret_value])
                        
                        
class KerasBatchGenerator(object):

    def __init__(self, data, num_steps, batch_size, dataset_size, skip_step=5):
        self.data = data
        self.num_steps = num_steps
        self.batch_size = batch_size
        self.dataset_size = dataset_size
        # this will track the progress of the batches sequentially through the
        # data set - once the data reaches the end of the data set it will reset
        # back to zero
        self.current_idx = 0
        # skip_step is the number of words which will be skipped before the next
        # batch is skimmed from the data set
        self.skip_step = skip_step
        
    def generate(self):
        x = np.zeros((self.batch_size, self.num_steps))
        y = np.zeros((self.batch_size, self.num_steps, self.dataset_size))
        while True:
            for i in range(self.batch_size):
                if self.current_idx + self.num_steps >= len(self.data):
                    # reset the index back to the start of the data set
                    self.current_idx = 0
                x[i, :] = self.data[self.current_idx:self.current_idx + self.num_steps]
                temp_y = self.data[self.current_idx + 1:self.current_idx + self.num_steps + 1]
                # convert all of temp_y into a one hot representation
                y[i, :, :] = to_categorical(temp_y, num_classes=self.dataset_size)
                self.current_idx += self.skip_step
            yield x, y
