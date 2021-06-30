FROM python:3.8-alpine

MAINTAINER  shan

RUN mkdir /code

COPY . /code

WORKDIR /code

RUN pip install mkdocs -i https://pypi.tuna.tsinghua.edu.cn/simple --trusted-host pypi.tuna.tsinghua.edu.cn

CMD ["mkdocs", "serve", "-a", "0.0.0.0:8000"]


