FROM nginx

RUN dd if=/dev/zero of=5gb bs=1MB count=5120 && mv 5gb /usr/share/nginx/html

# docker build . -f nginx.Dockerfile
# docker run --name nginx -d -p 8000:80 buildID
# request to http://localhost:8000/5gb
