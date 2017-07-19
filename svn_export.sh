#!/bin/sh
#导出指定版本之间的差异文件 如100到200之间的差异则导出100（不包括）-200（包括）的所有修改
USERNAME=""
PASSWORD=""
if [ $# -eq 0 ] ; then
	echo "You must select subject name"
	exit 1
fi

if [ $# -eq 1 ] ; then
	echo "You must useage like $0 old_version1(不包括) new_version(包括)"
	exit 1
fi

if [ $2 -gt $3 ] ; then
	echo "You must useage like $0 old_version1(不包括) new_version(包括)"
	exit 1
fi
    
SUBJECT=$1
OLD_VERSION=$2
NEW_VERSION=$3

SVN_URL="http://svn.hudong.net/${SUBJECT}"
#导出的目标路径
WORK_PATH="/Users/mmy83/code/${SUBJECT}-${OLD_VERSION}-${NEW_VERSION}"

echo "开始分析版本差异..."

DIFF_URL="svn diff -r ${OLD_VERSION}:${NEW_VERSION} --summarize --username ${USERNAME} --password ${PASSWORD} ${SVN_URL}"
echo ${DIFF_URL}

if [ ! -d "${WORK_PATH}" ]; then
	mkdir -p ${WORK_PATH}
fi


echo `${DIFF_URL}` >${WORK_PATH}/../${SUBJECT}-${OLD_VERSION}-${NEW_VERSION}-diff.txt
        
DIFF_NUM=`${DIFF_URL} |wc -l`
if [ ${DIFF_NUM} -ne 0 ]; then
	echo "差异文件共${DIFF_NUM}个,准备导出."
	DIFF_LIST=`${DIFF_URL}`
	#echo ${DIFF_LIST}
	NUM=0
	SKIP=0
	for FIELD in ${DIFF_LIST} ; do
		#长度小于3（A、M、D、AM即增加且修改）即是更新标识，否则为url
		if [ ${#FIELD} -lt 3 ]; then
			let NUM+=1
			SKIP=0
			if [ "${FIELD}" == "D" ]; then
			#下一个应该跳过
				SKIP=1
			fi
			continue
		fi
	
		#若为删除文件则不必导出
		if [ ${SKIP} -eq 1 ]; then
			echo ${NUM}.'是删除操作,跳过:'${FIELD}
			continue
		fi
	
		#替换得到相对路径
		DIFF_FILE=${FIELD//${SVN_URL}/}
		#echo ${NUM}.' '${DIFF_FILE}
	
		FILE_NAME=`basename ${DIFF_FILE}`
		FOLDER_NAME=`dirname ${DIFF_FILE}`
		FOLDER_PATH="${WORK_PATH}${FOLDER_NAME}"
		#echo ${FILE_NAME}' '${FOLDER_NAME}' '${FOLDER_PATH}

		if test ! -e "${FOLDER_PATH}"; then
			mkdir -p ${FOLDER_PATH}
		fi

		CMD="svn export -r ${NEW_VERSION} '${SVN_URL}${DIFF_FILE}'  '${FOLDER_PATH}/${FILE_NAME}' --force"
		#echo ${CMD}
		#echo ${NUM}.' '
		echo ${CMD}|sh
	done
	echo -e "版本号:"${OLD_VERSION}"->"${NEW_VERSION} "\t时间:" $(date +"%Y-%m-%d %H:%M:%S")>> ${WORK_PATH}/../${OLD_VERSION}-${NEW_VERSION}-log.txt
	echo "完成"
else
	echo "版本间没有差异"
fi
