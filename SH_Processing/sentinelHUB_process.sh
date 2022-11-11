docker build -t sentinelhub_proccess:0.0.1 --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) ./sentinelhub
docker run --rm -it \
            -v ~/.aws:/home/user/.aws \
            -v $(pwd):/sentinelHUB \
            --name sentienlHUB \
            sentinelhub_proccess:0.0.1 \
            bash ./sentinelhub/main.sh -b cc-datashare-sentinelhub -r 0f2b11df-405a-4dd7-98c2-119e5b728081 -c finland -s spring -o .