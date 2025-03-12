#!/usr/bin/env python
import socket
import validators
import logging
from flask import Flask, request, jsonify
from Wappalyzer import Wappalyzer, WebPage
import concurrent.futures

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)

# Create a ThreadPoolExecutor to handle multiple requests
executor = concurrent.futures.ThreadPoolExecutor(max_workers=10)


def analyze_website(url):
    """Function to analyze the website using Wappalyzer"""
    try:
        wappalyzer = Wappalyzer.latest()
        webpage = WebPage.new_from_url(url)
        analysis = wappalyzer.analyze_with_versions_and_categories(webpage)
        return {'url': url, 'analysis': analysis}
    except Exception as e:
        return {'url': url, 'error': str(e)}


@app.route('/site_info', methods=['GET'])
def analyze_site():
    """API endpoint to analyze a site concurrently"""
    url = request.args.get('url')
    
    if not url or not validators.url(url):
        return jsonify({'error': 'Invalid or missing URL'}), 400

    # Submit task to thread pool
    future = executor.submit(analyze_website, url)
    result = future.result()  # Blocking call, better approach is async handling

    return jsonify(result)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, threaded=True)
