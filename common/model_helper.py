import tensorflow as tf
import matplotlib.pyplot as plt
import numpy as np


def get_embeddings(model: tf.keras.Model, data):
    """
    model: the model that's has been built with tf.keras.Model
    data: data that preprocessed with tf.keras.preprocessing.image_dataset_from_directory function

    :return: embeddings, images, labels

    """

    return None


def show_images(idxs, images, row=1):
    plt.figure(figsize=(15, 12))
    for i in range(len(idxs)):
        plt.subplot(row, 3, i + 1)
        plt.axis('off')
        plt.imshow(np.array(images[idxs[i]], np.int32))
