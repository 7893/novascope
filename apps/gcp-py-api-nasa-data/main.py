# ~/novascope/apps/gcp-py-api-nasa-data/main.py
def main(request):
    """Responds to any HTTP request.
    Args:
        request (flask.Request): HTTP request object.
    Returns:
        The response text or any set of values that can be turned into a
        Response object using
        `make_response <http://flask.pocoo.org/docs/1.0/api/#flask.Flask.make_response>`.
    """
    print("ns-api-nasa-data called")
    return "Hello from ns-api-nasa-data (placeholder)!"