# Post install

webserver 접속 > 로그인 > Admin > Connections

new Connection(+ 버튼)

Connection id = s3_conn
Connection type = Amazon Web Service
Extra = {
  "host": "MINIO GATEWAY 주소",
  "aws_access_key_id": "MINIO 아이디",
  "aws_secret_access_key": "MINIO 비밀번호"
}