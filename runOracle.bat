@echo off
REM docker network create dev-net
REM -------------------------------
REM PULL IMAGE
REM -------------------------------
REM docker pull doctorkirk/oracle-19c
REM docker pull jaspeen/oracle-xe-11g


REM -------------------------------
REM run IMAGE
REM 
REM * KO16KSC5601
REM   완성형 한글- 일반적으로 많이 사용되며 2350자의 한글, 4888자의 한자, 히라카나, 카타카나, 영문 및 각종 기호를 포함하고 있음.  (한글바이트: 2byte)
REM
REM * KO16MSWIN949
REM   조합형 한글- 완성형을 포함하여 11172자의 한글을 표현함 (한글바이트: 2byte)
REM
REM * AL32UTF8 
REM   Unicode의 CES 중 하나- 11172자의 한글을 지원 (한글바이트: 3byte)
REM -------------------------------
docker run --name oracle --network dev-net -d -p 1521:1521 -e TZ=Asia/Seoul -e ORACLE_SID=ORAMYDATA -e ORACLE_PWD=Qudrhks2! -e ORACLE_CHARACTERSET=AL32UTF8 -v D:\Docker\mount\oracle\oradata:/opt/oracle/oradata doctorkirk/oracle-19c
REM docker run --name oracle --network dev-net -d -p 1521:1521 -e TZ=Asia/Seoul -v D:\Docker\mount\oracle\oradata:/u01/app/oracle/oradata -v D:\Docker\mount\oracle\dbs:/u01/app/oracle/dbs jaspeen/oracle-xe-11g
