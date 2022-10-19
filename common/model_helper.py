import tensorflow as tf
import matplotlib.pyplot as plt
import numpy as np
import cv2
import requests
import os


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


def save_image_cv(url, scale_percent, path, default_size=False):
    resp = requests.get(url, stream=True).raw
    image = np.asarray(bytearray(resp.read()), dtype="uint8")
    if image is None:
        return
    image = cv2.imdecode(image, cv2.IMREAD_COLOR)

    width = 224
    height = 224

    if default_size is False:
        width = int(image.shape[1] * scale_percent / 100)
        height = int(image.shape[0] * scale_percent / 100)

    dsize = (width, height)
    output = cv2.resize(image, dsize)

    cv2.imwrite(path, output)


def make_dataset_cv(bran_id, dataset_name, datasource, class_names, iteration=None):
    # RENK range is removed. 19-10-2022
    problems_of_paths = []
    try:
        base = os.path.abspath(os.path.join(os.path.dirname(os.getcwd()), '.'))
        path = os.path.join('datasets', dataset_name)
        path = os.path.join(base, path)
        if not os.path.isdir(path):
            os.mkdir(path)
        path = os.path.join(path, f'brand_{bran_id}')
        if not os.path.isdir(path):
            os.mkdir(path)
        # datasets/dataset/brand_id

        iterator = 0
        for index, row in class_names.iterrows():
            _class = row['CinsiyetKodu'] + '-' + row['UrunGrubuKodu']
            folder = os.path.join(path, _class)
            res = datasource.query(f'MarkaKodu == "{bran_id}" and CinsiyetKodu == "{row.CinsiyetKodu}" and '
                                   f'UrunGrubuKodu == "{row.UrunGrubuKodu}"')

            # if exists any data
            if res.shape[0] > 0:
                # check the folder exist
                if not os.path.isdir(folder):
                    os.mkdir(folder)

                # add the imgs to the folder
                for img_index, img_row in res.iterrows():
                    try:
                        save_image_cv(img_row['cUrl'], 50, os.path.join(folder, str(img_index) + '.png'), True)
                        if iteration is not None and iterator == iteration:
                            break
                        else:
                            iterator += 1
                    except Exception as e2:
                        problems_of_paths.append(os.path.join(folder, str(img_index) + '.jpg'))
                        print(e2)
                        continue

    except Exception as e:
        print('An exception occurred.', e)

    return problems_of_paths
