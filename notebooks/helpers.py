import pandas as pd 
import tensorflow as tf 
import matplotlib.pyplot as plt 
import pickle
from sklearn.metrics import precision_score, recall_score, f1_score


def predict(paths: list, model: tf.keras.models.Model, dims: tuple = (224, 224, 3)):
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
        print(i)
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

def plot_recall_precision_curve(y_hat, y_actual, base_threshold = 0.2):
    result_all_metrics = [] 
    while base_threshold < 1:
        y_hats = y_hat.copy() 
        y_hats[y_hats >= base_threshold] = 1
        y_hats[y_hats < base_threshold] = 0 

        result_all_metrics.append({
            "threshold": base_threshold, 
            "precision_weighted": round(precision_score(y_actual, y_hats, average="weighted"),2),
            "recall_weighted": round(recall_score(y_actual, y_hats, average="weighted"),2), 
            "f1_score_weighted": round(f1_score(y_actual, y_hats, average="weighted"),2)
        })
        
        base_threshold = base_threshold + 0.025

    figure, axis = plt.subplots(1, 4, figsize=(8,8))
    figure.tight_layout()
    recalls = [item["recall_weighted"] for item in result_all_metrics] 
    precisions = [item["precision_weighted"] for item in result_all_metrics] 
    f1_scores = [item["f1_score_weighted"] for item in result_all_metrics] 
    thresh = [item["threshold"] for item in result_all_metrics]

    axis[0].plot(recalls, precisions, '-o', c="#d62728")
    axis[0].set_title("Recall vs Precision")
    axis[0].set_xlabel("Recall")
    axis[0].set_ylabel("Precision")

    axis[1].plot(f1_scores, thresh, '-o')
    axis[1].set_title("F1-Score vs Thresholds")
    axis[1].set_xlabel("F1-Score")
    axis[1].set_ylabel("Threshold")

    axis[2].plot(recalls, thresh, '-o', c="cyan")
    axis[2].set_title("Recall vs Thresholds")
    axis[2].set_xlabel("Recall")
    axis[2].set_ylabel("Threshold")

    axis[3].plot(precisions, thresh, '-o', c="purple")
    axis[3].set_title("Precision vs Thresholds")
    axis[3].set_xlabel("Precision")
    axis[3].set_ylabel("Threshold")

    plt.show()


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


# FOR PRE-PROCESSING
def row_cleaner(df, after_column=2):
    idx = [] 
    for index, row in df.iterrows():
        if(sum(row[after_column:].values) == 0):
            idx.append(index)
    return df[~df.index.isin(idx)] 

def col_cleaner(df, after_column=2):
    cols = []
    for col in df.columns[after_column:]:
        if sum(df[col].values) == 0: 
            cols.append(col)
    
    if len(cols) > 0: 
        print("Previos shape:", df.shape) 
        result = df[df.columns[~df.columns.isin(cols)]]
        print("After shape:", result.shape)
        return result
    print("Nothing changed.")
    return df
