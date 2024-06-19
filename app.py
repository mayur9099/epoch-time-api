import logging
from flask import Flask, jsonify
import time

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

app = Flask(__name__)

@app.route('/epoch', methods=['GET'])
def get_epoch_time():
    logger.debug("Processing /epoch request")
    return jsonify({"The current epoch time": int(time.time())})

if __name__ == '__main__':
    logger.debug("Starting Flask application")
    app.run(host='0.0.0.0', port=5000)
