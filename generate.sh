for x in pdf mobi epub ; do docker run -d --name gitlab-ci.$x -v $PWD:/gitbook -w /gitbook goffinet/gitbook gitbook $x . gitlab-ci.goffinet.org.$x ; done
