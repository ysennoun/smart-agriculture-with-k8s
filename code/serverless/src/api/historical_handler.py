#https://spark.apache.org/docs/latest/sql-data-sources-parquet.html
#https://stackoverflow.com/questions/21510360/how-to-get-the-output-from-jar-execution-in-python-codes
from subprocess import Popen, PIPE, STDOUT

p = Popen(['java', '-jar', './GET_DB_DATA.jar'], stdout=PIPE, stderr=STDOUT)

if p.stderr:
    print(p.stderr)

if p.stdout:
    for line in p.stdout:
        print(line)
