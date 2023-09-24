python3 manage.py migrate;
service uwsgi start; 
service nginx start;
tail -f /dev/null;