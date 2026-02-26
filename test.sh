# aws ecr get-login-password --profile cd-read | docker login --username AWS --password-stdin https://849210807105.dkr.ecr.ap-southeast-2.amazonaws.com
base="849210807105.dkr.ecr.ap-southeast-2.amazonaws.com/rwwa.awesomecapability/api"
src="${base}:latest"
dst="${base}:devl-0.0.1"
# docker buildx imagetools create --append --tag $dst $src
sudo docker manifest inspect "${src}"
# sudo docker tag "${src}" "${dst}"
# sudo docker push "${dst}"
