python3 manage.py migrate;
python3 manage.py init;
service uwsgi start; 
service nginx start;
tail -f /dev/null;