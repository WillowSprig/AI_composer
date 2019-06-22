
##from keras.preprocessing import sequence as ksequence
import keras.layers as klayers
from keras.models import Sequential as Seq_model
from keras.utils import to_categorical
import numpy as np
import tensorflow.data as tfData

# create dictionary for rhythm values
def make_rhythm_dict():
    next = []
    for pow in range(6):
        next.append(1/(2**pow))
    for idx in range(5):
        next.append(next[idx]+next[idx+1])
    for idx in range(4):
        next.append(next[idx]+next[idx+2])
    for idx in range(3):
        next.append(next[idx]+next[idx+3])
    for idx in range(2):
        next.append(next[idx]+next[idx+4])
    next.append(next[0]+next[-1])
    return dict(zip(next, range(len(next))))


def create_networks(notes_size=128, rhythm_size=18, num_steps=10, hidden_size=200):
    # create model for note numbers
    notes_model = Seq_model()
    notes_model.add(klayers.Embedding(notes_size, hidden_size, input_length=num_steps))
    notes_model.add(klayers.LSTM(hidden_size, return_sequences=True))
    notes_model.add(klayers.LSTM(hidden_size, return_sequences=True))
    ##if use_dropout:
    notes_model.add(klayers.Dropout(0.5))
    notes_model.add(klayers.TimeDistributed(klayers.Dense(notes_size)))
    notes_model.add(klayers.Activation('softmax'))

    notes_model.compile(loss='mean_squared_error', optimizer='adam', metrics=['accuracy'])

    # create model for rhythm values
    rhythm_model = Seq_model()
    rhythm_model.add(klayers.Embedding(rhythm_size, hidden_size, input_length=num_steps))
    rhythm_model.add(klayers.LSTM(hidden_size, return_sequences=True))
    rhythm_model.add(klayers.LSTM(hidden_size, return_sequences=True))
    ##if use_dropout:
    rhythm_model.add(klayers.Dropout(0.5))
    rhythm_model.add(klayers.TimeDistributed(klayers.Dense(rhythm_size)))
    rhythm_model.add(klayers.Activation('softmax'))

    rhythm_model.compile(loss='mean_squared_error', optimizer='adam', metrics=['accuracy'])

    return notes_model, rhythm_model, num_steps


def run_networks(notes_model, rhythm_model, dataset, rhythm_dict, iterations=20, num_steps=10, batch_size=20,
                num_epochs=20, notes_size=128, rhythm_size=18):
    ret_value = []

    notes_generator = KerasBatchGenerator(dataset[:,0], num_steps, batch_size, notes_size, skip_step=num_steps//2)
    rhythm_generator = KerasBatchGenerator(dataset[:,1], num_steps, batch_size, rhythm_size, skip_step=num_steps//2)
    # model.fit(tfData.Dataset.from_tensors(dataset), steps_per_epoch=20,
                        # epochs=num_epochs, shuffle=False)
    notes_model.fit_generator(notes_generator.generate(), steps_per_epoch=dataset.shape[0]//(batch_size*num_steps),
                        epochs=num_epochs, shuffle=False)
    rhythm_model.fit_generator(rhythm_generator.generate(), steps_per_epoch=dataset.shape[0]//(batch_size*num_steps),
                        epochs=num_epochs, shuffle=False)

    for i in range(iterations):
        notes_data = next(notes_generator.generate())
        rhythm_data = next(rhythm_generator.generate())
        notes_prediction = notes_model.predict(notes_data[0])
        rhythm_prediction = rhythm_model.predict(rhythm_data[0])

        predict_note = notes_prediction[:, num_steps-1, :].argmax(0).argmax()
        predict_rhythm = rhythm_prediction[:, num_steps-1, :].argmax(0).argmax()
        ret_value.append((predict_note, rhythm_dict[predict_rhythm]))
    return notes_prediction, rhythm_prediction, np.array(ret_value)


class KerasBatchGenerator(object):

    def __init__(self, data, num_steps, batch_size, dataset_size, skip_step=5):
        self.data = data
        self.num_steps = num_steps
        self.batch_size = batch_size
        if dataset_size == 0:
            self.dataset_size = len(numpy.unique(data))
        else:
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
