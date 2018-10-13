FROM lambci/lambda:build-python3.6

########################################
# Add lambda code
########################################

WORKDIR /var/task

COPY ./ ./

RUN pip install -t . -r requirements.txt
