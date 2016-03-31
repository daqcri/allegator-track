from flask import render_template, request, redirect, Blueprint, session, jsonify, url_for

#Models 
from app.models import DatasetModels
from app.models import RedisCache

dataset = Blueprint("dataset", __name__, url_prefix="/dataset", template_folder="views")

@dataset.route("/upload", methods = ['GET', 'POST'])
def upload():
    """
    Uploading a dataset with input parameters
    """
    
    if request.method == 'GET':
        return jsonify({'status': 'Error!', 'message': 'Please use POST request'})
    else:
        data = session['data']
        arg1 = data['arg1'].lower()
        rel = data['rel'].lower()
        arg2 = data['arg2'].lower()
        arg2 = arg2.replace(' ','')

        hash_name = 'dataset_map'
        hash_key = '{0}_{1}_{2}'.format(arg1, rel, arg2)

        modler = DatasetModels()
        current_ids = modler.fetch_ids('claims')

        url = RedisCache.fetchValue(hash_name, hash_key, 'dataset_url')

        if not url:
            return jsonify({'status': 'Error!', 'message': 'Url not found'})
        else:
            file_name = "{0}.csv".format(hash_key)
            status_code = modler.upload_dataset(url, 'claims', file_name)
            if status_code != 200:
                return jsonify({'status': 'Error!', 'message': 'Dataset Uploaded'})
            else:
                new_ids = modler.fetch_ids('claims')
                latest_id = list(set(new_ids) - set(current_ids))
                RedisCache.createHash(hash_name, hash_key, {'dataset_id': latest_id[0]})
                RedisCache.createHash('runset_map', hash_key, {'dataset_id': latest_id[0]})

                return redirect(url_for('runset.create_runset'), code=307)