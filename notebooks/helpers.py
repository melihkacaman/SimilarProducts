import pandas as pd 

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