#***********************************************************************
# Function compress_arch_logs: Compress all archive logs for 
# all uncompressed redo logs upto the most recently archived sequence#  
# sequence number in database 
# example: compress_arch_logs $ORACLE_SID $LOGFILE 
#***********************************************************************
function compress_arch_logs {
   typeset SID=$1
   typeset LOG=$2
   typeset -i FSEQ=0
   typeset -i  OLDEST=0

   # Get achive log format
   typeset SQL1="select value from v\$parameter where name='log_archive_format';"
   RET_VAL=""
   dba_handle "$SQL1"
   if (( $? != ${STAT_OK} ))
   then
       print "  Get log_archive_format returns error."
       return ${ST_FAIL}
   fi

   PRE0=$(print  ${RET_VAL}|awk '{print $NF}'|nawk -F"%s" '{print $1}')
   PRE1=$(print ${PRE0}|nawk -F"%t" '{print $1}') 
   PRE2=$(print ${PRE0}|nawk -F"%t" '{print $2}') 
   EXT=$(print  ${RET_VAL}|awk '{print $NF}'|nawk -F"%s" '{print $2}')

   typeset SQL="select thread#||':'||sequence#||':'||archived||':'||status \
	from v\$log order by 1 desc;"
    # Get log sequence number
   RET_VAL=""
   dba_handle "$SQL"
   if (( $? != ${STAT_OK} ))
   then
         print "  Get log sequences number failed."
         return ${ST_FAIL}
   fi

   typeset -i SEQ=0
   typeset -i CNT=0

   print "  Compress most recent archive logs appearing in v\$logs"  
   print "${RET_VAL}"|while read ALL
   do
         print "$ALL" |awk -F: '{print $1, $2,$3, $4}' |read THR SEQ YN STAT
         PRE=${PRE1}${THR}${PRE2}
   if [[ ${SEQ} -ne 0 ]]
   then
     if [[ $YN = "YES" ]] 
     then
       if [[ -f ${SRC_ARCH_DIR}/${PRE}${SEQ}${EXT} ]]
       then
           print "  ${SRC_ARCH_DIR}/${PRE}${SEQ}${EXT} -  compressed" \
    	   	|tee -a $LOG
           ${GZIP} ${SRC_ARCH_DIR}/${PRE}${SEQ}${EXT} 2>/dev/null

           elif [[ -f ${SRC_ARCH_DIR}/${PRE}${SEQ}${EXT}.gz ]] 
           then
           print  "  ${SRC_ARCH_DIR}/${PRE}${SEQ}${EXT}  - Already Compressed" \
       		|tee -a  ${LOG} 
           elif [[ -f ${SRC_ARCH_DIR}/${PRE}${SEQ}${EXT}.Z ]] 
           then
           print  "  ${SRC_ARCH_DIR}/${PRE}${SEQ}${EXT}  - Already Compressed" \
       		|tee -a  ${LOG} 
           else
              print  "  ${SRC_ARCH_DIR}/${PRE}${SEQ}${EXT}  - not found!" \
		|tee -a  ${LOG} 
           fi
        CNT=$CNT+1
        fi
    let OLDEST=${SEQ}
    fi
    done
    
    print "  Compress all other uncompressed archive logs." 
    export END_SEQ=$((${OLDEST}+$CNT-1))
    let CNT=0
    typeset -r AFILES="${PRE}*${EXT}"
    ls  ${SRC_ARCH_DIR}/${AFILES}|while read FILE
    do
	FNAME=$(basename $FILE)

	let FSEQ=$(print $FNAME|awk -F_ '{print $3}'|awk -F. '{print $1}')
	if [[ $FSEQ -lt $OLDEST ]]
	then
        	if [[ $CNT -eq 0 ]] 
       	 	then
       		    	export START_SEQ=$FSEQ
		fi
		${GZIP} ${SRC_ARCH_DIR}/${FNAME} 2>/dev/null
                let CNT=$CNT+1
	fi
    done
    print "Start archive seq#: $START_SEQ"
    print "End archive seq#:  $END_SEQ"
    return ${STAT_OK}
}

#***********************************************************************
# Function proc_one_thread_archs: 
#   Compress and remote copy all archive logs for 
# all uncompressed redo logs upto the most recently archived sequence#  
# sequence number in database 
# example: compress_copy_arch_logs $ORACLE_SID
# global varibal  ${REMOTE_ACCT}, ${SID_RMT_TOP_DIR} needed
#***********************************************************************
function proc_one_thread_archs {
   typeset  THR=$1
   typeset -i FSEQ=0
   typeset -i OLDEST=0
   typeset -i SEQ=0
   typeset -i CNT=0
   typeset SQL="select sequence#||':'||archived||':'||status \
	from v\$log where thread#=$THR order by 1 desc;"
   # Get log sequence number
   RET_VAL=""
   dba_handle "$SQL"
   if (( $? != ${STAT_OK} ))
   then
       print "  Get log sequences number failed."
       return ${ST_FAIL}
   fi
   typeset -r RET_VAL1=${RET_VAL} 
   print "${RET_VAL1}"|while read ALL
   do
   print "$ALL" |grep -v Connect|awk -F: '{print $1, $2,$3}' |read SEQ YN STAT
   typeset   PRE=${PRE1}${THR}${PRE2}
   if [[ ${SEQ} -ne 0 ]]
   then
     if [[ $YN = "YES" ]] 
     then
       if [[ -f ${SRC_ARCH_DIR}/${PRE}${SEQ}${EXT} ]]
       then
          print "  ${SRC_ARCH_DIR}/${PRE}${SEQ}${EXT} -  compressed" 
          ${GZIP} ${SRC_ARCH_DIR}/${PRE}${SEQ}${EXT} 2>/dev/null
          if [[ $REMOTE = $TRUE ]] then
  	      scp -p ${SRC_ARCH_DIR}/${PRE}${SEQ}${EXT}.gz \
              ${REMOTE_ACCT}:${SID_RMT_TOP_DIR}/arch
          else
  	      cp -p ${SRC_ARCH_DIR}/${PRE}${SEQ}${EXT}.gz \
              ${SID_LOC_TOP_DIR}/arch
          fi
	
          if (( $? != ${STAT_OK} ))
          then
              print "  Copy ${PRE}${SEQ}${EXT} failed."
     	      return ${ST_FAIL}
          fi

       elif [[ -f ${SRC_ARCH_DIR}/${PRE}${SEQ}${EXT}.gz ]] 
       then
           print  "  ${SRC_ARCH_DIR}/${PRE}${SEQ}${EXT}  - Already Compressed" 
       elif [[ -f ${SRC_ARCH_DIR}/${PRE}${SEQ}${EXT}.Z ]] 
       then
           print  "  ${SRC_ARCH_DIR}/${PRE}${SEQ}${EXT}  - Already Compressed" 
       else
           print  "  ${SRC_ARCH_DIR}/${PRE}${SEQ}${EXT}  - not found!" 
       fi
     fi
     CNT=$CNT+1
     let OLDEST=${SEQ} # oldest redo log file 
   fi
   done
    
   print "  Compress all other uncompressed archive logs." 
   export END_SEQ=$((${OLDEST}+$CNT-1)) #the newest sequence number
   let CNT=0
   typeset -r AFILES="${PRE}*${EXT}"
   ls  ${SRC_ARCH_DIR}/${AFILES}|while read FILE
   do
      FNAME=$(basename $FILE)

      let FSEQ=$(print $FNAME|awk -F_ '{print $3}'|awk -F. '{print $1}')
      if [[ $FSEQ -lt $OLDEST ]] #older than oldest redo log
      then
       	if [[ $CNT -eq 0 ]] 
       	then
       	    	export START_SEQ=$FSEQ
	fi
	${GZIP} ${SRC_ARCH_DIR}/${FNAME} 2>/dev/null
        if [[ $REMOTE = $TRUE ]] then
            scp -p ${SRC_ARCH_DIR}/${PRE}${FSEQ}${EXT}.gz \
            ${REMOTE_ACCT}:${SID_RMT_TOP_DIR}/arch
        else
            cp -p ${SRC_ARCH_DIR}/${PRE}${FSEQ}${EXT}.gz \
            ${SID_LOC_TOP_DIR}/arch
        fi
        if (( $? != ${STAT_OK} ))
        then
              print "  Copy ${PRE}${FSEQ}${EXT} failed."
             return ${ST_FAIL}
        fi
                let CNT=$CNT+1
      fi
    done
   return ${STAT_OK}
}
