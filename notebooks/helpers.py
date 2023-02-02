import pandas as pd 
import tensorflow as tf 
import matplotlib.pyplot as plt 
import pickle


def predict(paths: str, model: tf.keras.models.Model, dims: tuple = (224, 224, 3)):
    """
    model: model which you want to predict with   
    path: paths of the image 
    dims: default dim of the image 
    """ 
    result = []  
    i = 0 
    for path in paths:
        img = tf.io.read_file(path) 
        img = tf.image.decode_jpeg(img, channels=3) 
        img = tf.image.resize(img, [dims[0], dims[1]]) 
        img = tf.reshape(img, [1, dims[0], dims[1], dims[2]])

        result.append(model.predict(img, verbose=0)) 
        i = i + 1 
        if i % 100 == 0: 
            print(f"{i} th iteration. You have {len(paths)} inputs. ")

    return result 

def evaluate_img(path: str, model: tf.keras.models.Model, columns: list, dims: tuple = (224, 224, 3), threshold: int = 0.5):
    """
    model: model which you want to predict with   
    path: path of the image 
    dims: default dim of the image 
    threshold: the threshold value, up of it 1 otherwise 0 
    """

    img = tf.io.read_file(path) 
    img = tf.image.decode_jpeg(img, channels=3) 
    img = tf.image.resize(img, [dims[0], dims[1]]) 
    img = tf.reshape(img, [1, dims[0], dims[1], dims[2]]) 


    preds = model.predict(img)
    preds[preds > threshold] = 1 
    preds[preds <= threshold] = 0  

    result = pd.Series(preds.squeeze()) 
    result.index = columns 

    return result

def show_image(path, width=224, height=224): 
    img = tf.io.read_file(path) 
    img = tf.image.decode_jpeg(img, channels=3)
    img = tf.image.resize(img, [width, height], antialias=False) 
    img = img / tf.constant([255], dtype=tf.float32) 

    plt.imshow(img) 
    plt.show()

def to_csv(dataframe: pd.DataFrame, path:str): 
    """
        It save the dataframe into the folder which path points. 
        Also, it will add the dtypes as a record as a last row. 
    """ 
    dataframe.loc[-1] = dataframe.dtypes 
    dataframe.index = dataframe.index + 1 
    dataframe.sort_index(inplace=True) 
    dataframe.to_csv(path, index=False) 

def read_csv_with_dtypes(path:str):
    """
        CSV file has to have its dtypes at the last row. 
    """
    dtypes = pd.read_csv(path, nrows=1).iloc[0].to_dict() 
    return pd.read_csv(path, dtype=dtypes, skiprows=[1]) 


def save_with_pickle(path, file):
    with open(path, 'wb') as handle:
        pickle.dump(file, handle)