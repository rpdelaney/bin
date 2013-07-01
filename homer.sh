#!/bin/bash
#
# Homer v1.0b1, Sept 2011
#
# by Cosimo Lupo (lupocos@gmail.com, http://bookscanner.pbworks.com/)
#
#   The script loads a directory of images which is expected to contain 2n files,
# and applies to them a series of manipulations.
#   First, it allows to reorder a batch of JPEG images such that the first half and 
# the second half are interspersed: that is, the first half is renamed with"
# incremental odd numbers, while the second half is renamed with incremental even
# numbers.
#   Besides, the script allows to fix the orientation of the JPEG images, by rota-
# ting the pages on the right-hand side of book 90 degrees clockwise, and those on
# the left-hand side of the book 90 degrees counterclockwise.
#   Finally, it runs "Tesseract OCR", the open source optical character recogni-
# tion software, to extract the text from a batch of TIFF images , and then uses
# "PDFbeads" to bind the images and the text into a single, searchable PDF
# (<http://code.google.com/p/tesseract-ocr>, <http://rubygems.org/gems/pdfbeads>).
#   The renaming/rotating bit of the script is inspired by Matti Kariluoma's 
# "RenameAll.exe" (http://www.mattikariluoma.com/files/RenameAll.exe) from the 
# Cardboard Bookscanner project, Jan 2010. <http://www.instructables.com/id/
# Bargain-Price-Book-Scanner-From-A-Cardboard-Box>

if [[ -z "$1"  ]]; then
    echo "Usage: homer /path/to/input/directory [-r, -R, -L, -l \"lang\"] [-o \"output\"]"
    echo "Type \"homer -h\" (or \"--help\") for further information."
    exit 0
elif [[ "$1" == "--help" || "$1" == "-h" ]]; then
    clear
	echo
    echo "Homer v1.0b1, Sept 2011"
    echo "by Cosimo Lupo (lupocos@gmail.com, http://bookscanner.pbworks.com/)"
    echo
    echo "  The script loads a directory of images which is expected to contain 2n files,"
	echo "and applies to them a series of manipulations." 
    echo "  First, it allows to reorder a batch of JPEG images such that the first half and" 
	echo "the second half are interspersed: that is, the first half is renamed with" 
	echo "incremental odd numbers, while the second half is renamed with incremental even"
	echo "numbers."
    echo "  Besides, the script allows to fix the orientation of the JPEG images, by rota-"
	echo "ting the pages on the right-hand side of book 90 degrees clockwise, and those on"
	echo "the left-hand side of the book 90 degrees counterclockwise."
    echo "  Finally, it runs \"Tesseract OCR\", the open source optical character recogni-"
	echo "tion software, to extract the text from a batch of TIFF images , and then uses" 
	echo "\"PDFbeads\" to bind the images and the text into a single, searchable PDF"
    echo "(<http://code.google.com/p/tesseract-ocr>, <http://rubygems.org/gems/pdfbeads>)."
	echo "  The renaming/rotating bit of the script is inspired by Matti Kariluoma's" 
	echo "\"RenameAll.exe\" (http://www.mattikariluoma.com/files/RenameAll.exe) from the" 
	echo "Cardboard Bookscanner project, Jan 2010. <http://www.instructables.com/id/"
	echo "Bargain-Price-Book-Scanner-From-A-Cardboard-Box>"
	echo 
	echo "[ Press {ENTER} to see the usage info, or {x} to close...]"
	read -n 1 -s answer 
	if [ ! "$answer" == "" ]; then
		echo
		exit 0
	else
		echo	
		echo
		echo "Usage: homer /path/to/input/directory [-r, -R, -L, -l \"lang\"] [-o \"output\"]"
	    echo 
	    echo "Options:"
	    echo "-r, --rename" 
	    echo "    rename the first half of the files with incremental odd numbers, the second"
	    echo "    half with incremental even numbers (JPEG only);"
	    echo "-R, --right" 
	    echo "    rename (as above) and rotate the right-hand pages 90 degrees clockwise, and"
	    echo "    the left-hand pages 90 degrees counterclockwise, starting from the RIGHT "
	    echo "    pages (JPEG only);"
	    echo "-L, --left" 
	    echo "    rename and rotate (as above) starting from the LEFT pages (JPEG only);"
	    echo "-l, --lang" 
	    echo "    run Tesseract OCR and convert the images into a searchable PDF (TIFF only),"
	    echo "    type \"homer -l\" (or \"--lang\") to view the list of supported languages;"
	    echo "-o, --output"
	    echo "    for [-r, -R, -L], the output is the path to the directory where the renamed"
	    echo "        images should be saved (default is \$1/renamed);"
	    echo "    for [-l], the output is the path to the final PDF, or its filename (default " 
	    echo "        is \$PWD/out.pdf)."
		echo
	    exit 0
	fi
elif [[ "$1" == "-l" || "$1" == "--lang" ]]; then
	echo
	echo "Tesseract OCR supported languages:"
	echo 
	echo '- Bulgarian: "bul"'
	echo '- Catalan: "cat"'
	echo '- Czech: "ces"'
	echo '- Chinese (Simplified): "chi_sim"'
	echo '- Chinese (Traditional): "chi_tra"'
	echo '- Danish: "dan"'
	echo '- Danish (Fraktur): "dan-frak"'
	echo '- Dutch: "nld"'
	echo '- English: "eng"'
	echo '- Finnish: "fin"'
	echo '- French: "fra"'
	echo '- German: "deu"'
	echo '- German (Fraktur): "deu-frak"'
	echo '- Greek: "ell"'
	echo '- Hungarian: "hun"'
	echo '- Indonesian: "ind"'
	echo '- Italian: "ita"'
	echo '- Japanese: "jpn"'
	echo '- Korean: "kor"'
	echo '- Latvian: "lav"'
	echo '- Lithuanian: "lit"'
	echo '- Norwegian: "nor"'
	echo '- Polish: "pol"'
	echo '- Portuguese: "por"'
	echo '- Romanian: "ron"'
	echo '- Russian: "rus"'
	echo '- Slovakian: "slk"'
	echo '- Slovenian: "slv"'
	echo '- Spanish: "spa"'
	echo '- Serbian (Latin): "srp"'
	echo '- Swedish: "swe"'
	echo '- Swedish (Fraktur): "swe-frak"'
	echo '- Tagalog: "tgl"'
	echo '- Ukranian: "ukr"'
	echo '- Vietnamese: "vie"'
	exit 0
elif [[ ! -d $1 && ! `echo ${1:0:1} | grep "/"` == "" ]]; then
    echo "homer: \"$1\": No such folder" >&2
    exit 1
elif [[ `echo ${1:0:1} | grep "/"` == "" ]]; then
	if [[ ! -d "$PWD/$1" ]]; then
		echo "homer: \"$PWD/$1\": No such folder" >&2
   	 	exit 1	
   	else
   		set -- "$PWD/$1" "$2" "$3" "$4" "$5"
	fi
fi
if [[ -z "$2"  ]]; then
	echo
	echo "The input directory you have selected is:"
	echo
	echo "$1"
	echo
	ok=0
	while [[ $ok -eq 0 ]]
		do
		echo
		echo '- If you want to RENAME and ROTATE the images contained in the input directory:' 
		echo 
		echo '    * Press "1", if you started scanning from the RIGHT-HAND PAGES of the book;'
		echo 
		echo '    * Press "2", if you started scanning from the LEFT-HAND PAGES.'
		echo
		echo '- Press "3", if simply want to RENAME (without rotating) the images:'
		echo
		echo '- Press "4", if you have already processed the images using Scan Tailor, and now'
		echo '    wish to run Tesseract OCR software to produce a "searchable" PDF.'
		echo
		read -s -n 1 answer
		if [ "$answer" == "1" ]; then
			echo
			echo 'You have entered "1".' 
			ok=1
			if [ "$(which jpegtran)" == "" ]; then
				echo >&2 "The script requires jpegtran, but jpegtran is not installed. Aborting."
				exit 1
			else
				cd "$1"
				shopt -s nocaseglob
				count=`ls -1 *.jpg 2>/dev/null | wc -l`
				if [ $count != 0 ]; then 
					echo 'The images will be renamed and rotated starting from the RIGHT-HAND PAGES, and '
					echo 'will be saved into the "renamed" folder inside the input directory.'
					echo
					mkdir ".tmp"
					rm -R "renamed" &> /dev/null
					mkdir "renamed"
					COUNTER=`ls *.JPG | wc -l`
					RIGHT=$(($COUNTER / 2))
					LEFT=$(($COUNTER / 2))
					a=1
					b=1
					while [ "$RIGHT" != "0" ]; do
						new=$(printf "%04d.JPG" ${a})
						ARRAY=( $(ls *.JPG | head -n 1) ) 
						jpegtran -rotate 90 -optimize -outfile "$PWD/renamed/${new}" ${ARRAY[0]}
						mv ${ARRAY[0]} "$PWD/.tmp"
						echo "Processing image ${b}/$COUNTER"
						let a=a+2
						let RIGHT-=1
						let b=b+1
					done	
					a=2
					while [ "$LEFT" != "0" ]; do
						new=$(printf "%04d.JPG" ${a})
						ARRAY=( $(ls *.JPG | head -n 1) )
						jpegtran -rotate 270 -optimize -outfile "$PWD/renamed/${new}" ${ARRAY[0]} 
						mv ${ARRAY[0]} "$PWD/.tmp"
						echo "Processing image ${b}/$COUNTER"
						let a=a+2
						let LEFT-=1
						let b=b+1
					done
					echo
					echo "Cleaning up temporary files..."
					cd ".tmp"
					for i in *.JPG
						do cp $i "$1"
					done
					cd ..
					rm -R .tmp
					exit 0
				else
					echo "homer: No JPEG files found in the input directory."
					exit 1
				fi
			fi	
		elif [ "$answer" == "2" ]; then
		  echo
			echo 'You have entered "2".' 
			ok=1
			if [ "$(which jpegtran)" == "" ]; then
				echo >&2 "The script requires jpegtran, but jpegtran is not installed. Aborting."
				exit 1
			else
				cd "$1"
				shopt -s nocaseglob
				count=`ls -1 *.jpg 2>/dev/null | wc -l`
				if [ $count != 0 ]; then 
					echo 'The images will be renamed and rotated starting from the LEFT-HAND PAGES, and '
					echo 'will be saved into the "renamed" folder inside the input directory.'
					echo
					mkdir ".tmp"
					rm -R "renamed" &> /dev/null
					mkdir "renamed"
					COUNTER=`ls *.JPG | wc -l`
					RIGHT=$(($COUNTER / 2))
					LEFT=$(($COUNTER / 2))
					a=1
					b=1
					while [ "$LEFT" != "0" ]; do
						new=$(printf "%04d.JPG" ${a})
						ARRAY=( $(ls *.JPG | head -n 1) ) 
						jpegtran -rotate 270 -optimize -outfile "$PWD/renamed/${new}" ${ARRAY[0]}
						mv ${ARRAY[0]} "$PWD/.tmp"
						echo "Processing image ${b}/$COUNTER"
						let a=a+2
						let LEFT-=1
						let b=b+1
					done	
					a=2
					while [ "$RIGHT" != "0" ]; do
						new=$(printf "%04d.JPG" ${a})
						ARRAY=( $(ls *.JPG | head -n 1) )
						jpegtran -rotate 90 -optimize -outfile "$PWD/renamed/${new}" ${ARRAY[0]}
						mv ${ARRAY[0]} "$PWD/.tmp"
						echo "Processing image ${b}/$COUNTER"
						let a=a+2
						let RIGHT-=1
						let b=b+1
					done
					echo
					echo "Cleaning up temporary files..."
					cd ".tmp"
					for i in *.JPG
						do cp $i "$1"
					done
					cd ..
					rm -R .tmp
					exit 0
				else
					echo "homer: No JPEG files found in the input directory."
					exit 1
				fi
			fi	
		elif [ "$answer" == "3" ]; then
			cd "$1"
			shopt -s nocaseglob
			count=`ls -1 *.jpg 2>/dev/null | wc -l`
			if [ $count != 0 ]; then 
				echo
				echo 'The images will be renamed and saved into the "renamed" folder inside the input directory.'
				echo
				mkdir ".tmp"
				rm -R "renamed" &> /dev/null
				mkdir "renamed"
				COUNTER=`ls *.JPG | wc -l`
				RIGHT=$(($COUNTER / 2))
				LEFT=$(($COUNTER / 2))
				a=1
				b=1
				while [ "$RIGHT" != "0" ]; do
					new=$(printf "%04d.JPG" ${a})
					ARRAY=( $(ls *.JPG | head -n 1) ) 
					cp ${ARRAY[0]} "$PWD/renamed/${new}"
					mv ${ARRAY[0]} "$PWD/.tmp"
					echo "Renaming image ${b}/$COUNTER"
					let a=a+2
					let RIGHT-=1
					let b=b+1
				done	
				a=2
				while [ "$LEFT" != "0" ]; do
					new=$(printf "%04d.JPG" ${a})
					ARRAY=( $(ls *.JPG | head -n 1) )
					cp ${ARRAY[0]} "$PWD/renamed/${new}"
					mv ${ARRAY[0]} "$PWD/.tmp"
					echo "Renaming image ${b}/$COUNTER"
					let a=a+2
					let LEFT-=1
					let b=b+1
				done
				echo
				echo "Cleaning up temporary files..."
				cd ".tmp"
				for i in *.JPG
					do cp $i "$1"
				done
				cd ..
				rm -R .tmp
				echo
				exit 0
			else
				echo "homer: No JPEG files found in the input directory."
				exit 1
			fi
		elif [ "$answer" == "4" ]; then
			echo
			echo 'You have entered "4".' 
			ok=1
			if [ "$(which tesseract)" == "" ]; then
				echo >&2 "The script requires Tesseract OCR, which is not installed. Aborting."
				exit 1
			else
				cd "$1"
				shopt -s nocaseglob
				count=`ls -1 *.tif 2>/dev/null | wc -l`
				if [ $count != 0 ]; then
				# Tests if $1 is in the array ($2 $3 $4 ...).
					is_in() {
						value=$1
						shift
						for i in "$@"; do
							[[ $i == $value ]] && return 0
						done
						return 1
					}
					ok=0
					ARRAY=(bul cat ces chi_sim chi_tra dan dan-frak nld eng fin fra deu deu-frak ell hun ind ita jpn kor lav lit nor pol por ron rus slk slv spa srp swe swe-frak ukr vie)
					while [[ $ok -eq 0 ]]
					do
					echo "Please specify the language of the text that you want to recognize (e.g., type" 
					echo '"eng" for English). To view the complete list of supported languages, leave it'
					echo "blank and press [ENTER]:"
					echo
					read lang
					if [ -z "$lang" ]; then
						echo '- Bulgarian: "bul"'
						echo '- Catalan: "cat"'
						echo '- Czech: "ces"'
						echo '- Chinese (Simplified): "chi_sim"'
						echo '- Chinese (Traditional): "chi_tra"'
						echo '- Danish: "dan"'
						echo '- Danish (Fraktur): "dan-frak"'
						echo '- Dutch: "nld"'
						echo '- English: "eng"'
						echo '- Finnish: "fin"'
						echo '- French: "fra"'
						echo '- German: "deu"'
						echo '- German (Fraktur): "deu-frak"'
						echo '- Greek: "ell"'
						echo '- Hungarian: "hun"'
						echo '- Indonesian: "ind"'
						echo '- Italian: "ita"'
						echo '- Japanese: "jpn"'
						echo '- Korean: "kor"'
						echo '- Latvian: "lav"'
						echo '- Lithuanian: "lit"'
						echo '- Norwegian: "nor"'
						echo '- Polish: "pol"'
						echo '- Portuguese: "por"'
						echo '- Romanian: "ron"'
						echo '- Russian: "rus"'
						echo '- Slovakian: "slk"'
						echo '- Slovenian: "slv"'
						echo '- Spanish: "spa"'
						echo '- Serbian (Latin): "srp"'
						echo '- Swedish: "swe"'
						echo '- Swedish (Fraktur): "swe-frak"'
						echo '- Tagalog: "tgl"'
						echo '- Ukranian: "ukr"'
						echo '- Vietnamese: "vie"'
						echo
					elif ! is_in "$lang" "${ARRAY[@]}"; then
						echo "Not a permitted value. Try again." >&2
						echo
					else
						ok=1
					fi
					done
					echo
					echo "Please type the desired name of the final PDF file (without the .pdf extension):"
					echo
					read name
					echo
					echo "You have entered '$name'. Please wait while Tesseract is processing the files:"
					echo
					cd "$1"
					for img in *.tif
						do
						filename=${img%%.*}
						tesseract $img $filename -l $lang hocr 2>> tesseract-log.txt
						echo "   Processed $img"
					done
					echo
					echo "PDFbeads is now combining the images into a single PDF which will be saved inside \"$1\". Please wait..."
					pdfbeads --bg-compression JPG --output "$name.pdf" *.tif &> pdfbeads-log.txt
					if [[ ! -f $name.pdf ]]; then
						tail -1 pdfbeads-log.txt
						exit 1
					fi
				else
					echo "homer: No TIFF files found in the input directory."
					exit 1
				fi
			fi
		else
			echo
			echo
			echo '* Unrecognized option. Valid answers are "1", "2", or "3".' 
			echo "* Please try again (or close the window to abort):"
			echo
		fi
	done
elif [[ "$2" == "-r" || "$2" == "--rename" ]]; then
	if [[ -z "$3" ]]; then
		cd "$1"
		shopt -s nocaseglob
		count=`ls -1 *.jpg 2>/dev/null | wc -l`
		if [ $count != 0 ]; then 
			echo
			echo 'The images will be renamed and saved into the "renamed" folder inside the input directory.'
			echo
			mkdir ".tmp"
			rm -R "renamed" &> /dev/null
			mkdir "renamed"
			COUNTER=`ls *.JPG | wc -l`
			RIGHT=$(($COUNTER / 2))
			LEFT=$(($COUNTER / 2))
			a=1
			b=1
			while [ "$RIGHT" != "0" ]; do
				new=$(printf "%04d.JPG" ${a})
				ARRAY=( $(ls *.JPG | head -n 1) ) 
				cp ${ARRAY[0]} "$PWD/renamed/${new}"
				mv ${ARRAY[0]} "$PWD/.tmp"
				echo "Renaming image ${b}/$COUNTER"
				let a=a+2
				let RIGHT-=1
				let b=b+1
			done	
			a=2
			while [ "$LEFT" != "0" ]; do
				new=$(printf "%04d.JPG" ${a})
				ARRAY=( $(ls *.JPG | head -n 1) )
				cp ${ARRAY[0]} "$PWD/renamed/${new}"
				mv ${ARRAY[0]} "$PWD/.tmp"
				echo "Renaming image ${b}/$COUNTER"
				let a=a+2
				let LEFT-=1
				let b=b+1
			done
			echo
			echo "Cleaning up temporary files..."
			cd ".tmp"
			for i in *.JPG
				do cp $i "$1"
			done
			cd ..
			rm -R .tmp
			echo
			exit 0
		else
			echo "homer: No JPEG files found in the input directory."
			exit 1
		fi
	elif [[ ! "$3" == "-o" ]]; then
		echo "homer: \"$3\" is not a permitted option. See \"homer -h\" (or \"--help\")."
		exit 1
	elif [[ -z "$4" ]]; then
		echo "homer: Output directory not specified."
		exit 1
	elif [[ -d "$4" && "$4" == "$1" ]]; then
		echo "homer: The output folder cannot be the same as the input one."
		exit 1
	elif [[ ! `echo ${4:0:1} | grep "/"` == "" && -d "$4" ]]; then
		cd "$1"
		shopt -s nocaseglob
		count=`ls -1 *.jpg 2>/dev/null | wc -l`
		if [ $count != 0 ]; then 
			echo
			echo "The images will be renamed and saved into the \"$4\" folder."
			echo
			mkdir ".tmp"
			COUNTER=`ls *.JPG | wc -l`
			RIGHT=$(($COUNTER / 2))
			LEFT=$(($COUNTER / 2))
			a=1
			b=1
			while [ "$RIGHT" != "0" ]; do
				new=$(printf "%04d.JPG" ${a})
				ARRAY=( $(ls *.JPG | head -n 1) ) 
				cp ${ARRAY[0]} "$4/${new}"
				mv ${ARRAY[0]} "$1/.tmp"
				echo "Renaming image ${b}/$COUNTER"
				let a=a+2
				let RIGHT-=1
				let b=b+1
			done	
			a=2
			while [ "$LEFT" != "0" ]; do
				new=$(printf "%04d.JPG" ${a})
				ARRAY=( $(ls *.JPG | head -n 1) )
				cp ${ARRAY[0]} "$4/${new}"
				mv ${ARRAY[0]} "$1/.tmp"
				echo "Renaming image ${b}/$COUNTER"
				let a=a+2
				let LEFT-=1
				let b=b+1
			done
			echo
			echo "Cleaning up temporary files..."
			cd ".tmp"
			for i in *.JPG
				do cp $i "$1"
			done
			cd ..
			rm -R .tmp
			exit 0
		else
			echo "homer: No JPEG files found in the input directory."
			exit 1
		fi
	elif [[ ! `echo ${4:0:1} | grep "/"` == "" && -d `dirname "$4"` ]]; then
		cd "$1"
		shopt -s nocaseglob
		count=`ls -1 *.jpg 2>/dev/null | wc -l`
		if [ $count != 0 ]; then 
			echo
			echo "The images will be renamed and saved into the \"$4\" folder."
			echo
			mkdir "$4"
			mkdir ".tmp"
			COUNTER=`ls *.JPG | wc -l`
			RIGHT=$(($COUNTER / 2))
			LEFT=$(($COUNTER / 2))
			a=1
			b=1
			while [ "$RIGHT" != "0" ]; do
				new=$(printf "%04d.JPG" ${a})
				ARRAY=( $(ls *.JPG | head -n 1) ) 
				cp ${ARRAY[0]} "$4/${new}"
				mv ${ARRAY[0]} "$1/.tmp"
				echo "Renaming image ${b}/$COUNTER"
				let a=a+2
				let RIGHT-=1
				let b=b+1
			done	
			a=2
			while [ "$LEFT" != "0" ]; do
				new=$(printf "%04d.JPG" ${a})
				ARRAY=( $(ls *.JPG | head -n 1) )
				cp ${ARRAY[0]} "$4/${new}"
				mv ${ARRAY[0]} "$1/.tmp"
				echo "Renaming image ${b}/$COUNTER"
				let a=a+2
				let LEFT-=1
				let b=b+1
			done
			echo
			echo "Cleaning up temporary files..."
			cd ".tmp"
			for i in *.JPG
				do cp $i "$1"
			done
			cd ..
			rm -R .tmp
			exit 0
		else
			echo "homer: No JPEG files found in the input directory."
			exit 1
		fi
	elif [[ `echo ${4:0:1} | grep "/"` == "" && -d `dirname "$4"` ]]; then
		currentdir=$(PWD)
		cd "$1"
		shopt -s nocaseglob
		count=`ls -1 *.jpg 2>/dev/null | wc -l`
		if [ $count != 0 ]; then 
			if [[ ! -d "$currentdir/$4" ]]; then 
				mkdir "$currentdir/$4"
			elif [[ -d "$currentdir/$4" && "$currentdir/$4" == "$1" ]]; then
				echo "homer: The output folder cannot be the same as the input one."
				exit 1	
			fi
			echo
			echo "The images will be renamed and saved into the \"$currentdir/$4\" folder."
			echo
			mkdir ".tmp"
			COUNTER=`ls *.JPG | wc -l`
			RIGHT=$(($COUNTER / 2))
			LEFT=$(($COUNTER / 2))
			a=1
			b=1
			while [ "$RIGHT" != "0" ]; do
				new=$(printf "%04d.JPG" ${a})
				ARRAY=( $(ls *.JPG | head -n 1) ) 
				cp ${ARRAY[0]} "$currentdir/$4/${new}"
				mv ${ARRAY[0]} "$1/.tmp"
				echo "Renaming image ${b}/$COUNTER"
				let a=a+2
				let RIGHT-=1
				let b=b+1
			done	
			a=2
			while [ "$LEFT" != "0" ]; do
				new=$(printf "%04d.JPG" ${a})
				ARRAY=( $(ls *.JPG | head -n 1) )
				cp ${ARRAY[0]} "$currentdir/$4/${new}"
				mv ${ARRAY[0]} "$1/.tmp"
				echo "Renaming image ${b}/$COUNTER"
				let a=a+2
				let LEFT-=1
				let b=b+1
			done
			echo
			echo "Cleaning up temporary files..."
			cd ".tmp"
			for i in *.JPG
				do cp $i "$1"
			done
			cd ..
			rm -R .tmp
			exit 0
		else
			echo "homer: No JPEG files found in the input directory."
			exit 1
		fi
	elif [[ ! -d `dirname "$4"` ]]; then
		echo "homer: \"`dirname "$4"`\": no such folder"
		exit
	fi
elif [[ "$2" == "-R" || "$2" == "--right" ]]; then
	if [[ -z "$3" ]]; then
		if [ "$(which jpegtran)" == "" ]; then
			echo >&2 "The script requires jpegtran, but jpegtran is not installed. Aborting."
			exit 1
		else
			cd "$1"
			shopt -s nocaseglob
			count=`ls -1 *.jpg 2>/dev/null | wc -l`
			if [ $count != 0 ]; then 
				echo
				echo 'The images will be renamed and rotated starting from the RIGHT-HAND PAGES, and '
				echo 'will be saved into the "renamed" folder inside the input directory.'
				echo
				mkdir ".tmp"
				rm -R "renamed" &> /dev/null
				mkdir "renamed"
				COUNTER=`ls *.JPG | wc -l`
				RIGHT=$(($COUNTER / 2))
				LEFT=$(($COUNTER / 2))
				a=1
				b=1
				while [ "$RIGHT" != "0" ]; do
					new=$(printf "%04d.JPG" ${a})
					ARRAY=( $(ls *.JPG | head -n 1) ) 
					jpegtran -rotate 90 -optimize -outfile "$PWD/renamed/${new}" ${ARRAY[0]}
					mv ${ARRAY[0]} "$PWD/.tmp"
					echo "Processing image ${b}/$COUNTER"
					let a=a+2
					let RIGHT-=1
					let b=b+1
				done	
				a=2
				while [ "$LEFT" != "0" ]; do
					new=$(printf "%04d.JPG" ${a})
					ARRAY=( $(ls *.JPG | head -n 1) )
					jpegtran -rotate 270 -optimize -outfile "$PWD/renamed/${new}" ${ARRAY[0]} 
					mv ${ARRAY[0]} "$PWD/.tmp"
					echo "Processing image ${b}/$COUNTER"
					let a=a+2
					let LEFT-=1
					let b=b+1
				done
				echo
				echo "Cleaning up temporary files..."
				cd ".tmp"
				for i in *.JPG
					do cp $i "$1"
				done
				cd ..
				rm -R .tmp
				exit 0
			else
				echo "homer: No JPEG files found in the input directory."
				exit 1
			fi
		fi	
	elif [[ ! "$3" == "-o" ]]; then
		echo "homer: \"$3\" is not a permitted option. See \"homer -h\" (or \"--help\")."
		exit 1
	elif [[ -z "$4" ]]; then
		echo "homer: Output directory not specified."
		exit 1
	elif [[ -d "$4" && "$4" == "$1" ]]; then
		echo "homer: The output folder cannot be the same as the input one."
		exit 1
	elif [[ ! `echo ${4:0:1} | grep "/"` == "" && -d "$4" ]]; then
		if [ "$(which jpegtran)" == "" ]; then
			echo >&2 "The script requires jpegtran, but jpegtran is not installed. Aborting."
			exit 1
		else
			cd "$1"
			shopt -s nocaseglob
			count=`ls -1 *.jpg 2>/dev/null | wc -l`
			if [ $count != 0 ]; then 
				echo
				echo "The images will be renamed and rotated starting from the RIGHT-HAND PAGES, and "
				echo "will be saved into the \"$4\" folder."
				echo
				mkdir ".tmp"
				COUNTER=`ls *.JPG | wc -l`
				RIGHT=$(($COUNTER / 2))
				LEFT=$(($COUNTER / 2))
				a=1
				b=1
				while [ "$RIGHT" != "0" ]; do
					new=$(printf "%04d.JPG" ${a})
					ARRAY=( $(ls *.JPG | head -n 1) ) 
					jpegtran -rotate 90 -optimize -outfile "$4/${new}" ${ARRAY[0]}
					mv ${ARRAY[0]} "$1/.tmp"
					echo "Processing image ${b}/$COUNTER"
					let a=a+2
					let RIGHT-=1
					let b=b+1
				done	
				a=2
				while [ "$LEFT" != "0" ]; do
					new=$(printf "%04d.JPG" ${a})
					ARRAY=( $(ls *.JPG | head -n 1) )
					jpegtran -rotate 270 -optimize -outfile "$4/${new}" ${ARRAY[0]} 
					mv ${ARRAY[0]} "$1/.tmp"
					echo "Processing image ${b}/$COUNTER"
					let a=a+2
					let LEFT-=1
					let b=b+1
				done
				echo
				echo "Cleaning up temporary files..."
				cd ".tmp"
				for i in *.JPG
					do cp $i "$1"
				done
				cd ..
				rm -R .tmp
				exit 0
			else
				echo "homer: No JPEG files found in the input directory."
				exit 1
			fi
		fi
	elif [[ ! `echo ${4:0:1} | grep "/"` == "" && -d `dirname "$4"` ]]; then
		if [ "$(which jpegtran)" == "" ]; then
			echo >&2 "The script requires jpegtran, but jpegtran is not installed. Aborting."
			exit 1
		else
			cd "$1"
			shopt -s nocaseglob
			count=`ls -1 *.jpg 2>/dev/null | wc -l`
			if [ $count != 0 ]; then 
				echo
				echo "The images will be renamed and rotated starting from the RIGHT-HAND PAGES, and "
				echo "will be saved into the \"$4\" folder."
				echo
				mkdir "$4"
				mkdir ".tmp"
				COUNTER=`ls *.JPG | wc -l`
				RIGHT=$(($COUNTER / 2))
				LEFT=$(($COUNTER / 2))
				a=1
				b=1
				while [ "$RIGHT" != "0" ]; do
					new=$(printf "%04d.JPG" ${a})
					ARRAY=( $(ls *.JPG | head -n 1) ) 
					jpegtran -rotate 90 -optimize -outfile "$4/${new}" ${ARRAY[0]}
					mv ${ARRAY[0]} "$1/.tmp"
					echo "Processing image ${b}/$COUNTER"
					let a=a+2
					let RIGHT-=1
					let b=b+1
				done	
				a=2
				while [ "$LEFT" != "0" ]; do
					new=$(printf "%04d.JPG" ${a})
					ARRAY=( $(ls *.JPG | head -n 1) )
					jpegtran -rotate 270 -optimize -outfile "$4/${new}" ${ARRAY[0]} 
					mv ${ARRAY[0]} "$1/.tmp"
					echo "Processing image ${b}/$COUNTER"
					let a=a+2
					let LEFT-=1
					let b=b+1
				done
				echo
				echo "Cleaning up temporary files..."
				cd ".tmp"
				for i in *.JPG
					do cp $i "$1"
				done
				cd ..
				rm -R .tmp
				exit 0
			else
				echo "homer: No JPEG files found in the input directory."
				exit 1
			fi
		fi
	elif [[ `echo ${4:0:1} | grep "/"` == "" && -d `dirname "$4"` ]]; then
		currentdir=$(PWD)
		cd "$1"
		shopt -s nocaseglob
		count=`ls -1 *.jpg 2>/dev/null | wc -l`
		if [ $count != 0 ]; then
			if [[ ! -d "$currentdir/$4" ]]; then 
				mkdir "$currentdir/$4"
			elif [[ -d "$currentdir/$4" && "$currentdir/$4" == "$1" ]]; then
				echo "homer: The output folder cannot be the same as the input one."
				exit 1	
			fi
			echo
			echo "The images will be renamed and rotated starting from the RIGHT-HAND PAGES, and "
			echo "will be saved into the \"$currentdir/$4\" folder."
			echo
			mkdir ".tmp"
			COUNTER=`ls *.JPG | wc -l`
			RIGHT=$(($COUNTER / 2))
			LEFT=$(($COUNTER / 2))
			a=1
			b=1
			while [ "$LEFT" != "0" ]; do
				new=$(printf "%04d.JPG" ${a})
				ARRAY=( $(ls *.JPG | head -n 1) ) 
				jpegtran -rotate 270 -optimize -outfile "$currentdir/$4/${new}" ${ARRAY[0]}
				mv ${ARRAY[0]} "$1/.tmp"
				echo "Processing image ${b}/$COUNTER"
				let a=a+2
				let LEFT-=1
				let b=b+1
			done	
			a=2
			while [ "$RIGHT" != "0" ]; do
				new=$(printf "%04d.JPG" ${a})
				ARRAY=( $(ls *.JPG | head -n 1) )
				jpegtran -rotate 90 -optimize -outfile "$currentdir/$4/${new}" ${ARRAY[0]}
				mv ${ARRAY[0]} "$1/.tmp"
				echo "Processing image ${b}/$COUNTER"
				let a=a+2
				let RIGHT-=1
				let b=b+1
			done
			echo
			echo "Cleaning up temporary files..."
			cd ".tmp"
			for i in *.JPG
				do cp $i "$1"
			done
			cd ..
			rm -R .tmp
			exit 0
		else
			echo "homer: No JPEG files found in the input directory."
			exit 1
		fi
	elif [[ ! -d `dirname "$4"` ]]; then
		echo "homer: \"`dirname "$4"`\": no such folder"
		exit 1
	fi
elif [[ "$2" == "-L" || "$2" == "--left" ]]; then
	if [[ -z "$3" ]]; then
		if [ "$(which jpegtran)" == "" ]; then
			echo >&2 "The script requires jpegtran, but jpegtran is not installed. Aborting."
			exit 1
		else
			cd "$1"
			shopt -s nocaseglob
			count=`ls -1 *.jpg 2>/dev/null | wc -l`
			if [ $count != 0 ]; then 
				echo
				echo 'The images will be renamed and rotated starting from the LEFT-HAND PAGES, and '
				echo 'will be saved into the "renamed" folder inside the input directory.'
				echo
				mkdir ".tmp"
				rm -R "renamed" &> /dev/null
				mkdir "renamed"
				COUNTER=`ls *.JPG | wc -l`
				RIGHT=$(($COUNTER / 2))
				LEFT=$(($COUNTER / 2))
				a=1
				b=1
				while [ "$LEFT" != "0" ]; do
					new=$(printf "%04d.JPG" ${a})
					ARRAY=( $(ls *.JPG | head -n 1) ) 
					jpegtran -rotate 270 -optimize -outfile "$PWD/renamed/${new}" ${ARRAY[0]}
					mv ${ARRAY[0]} "$PWD/.tmp"
					echo "Processing image ${b}/$COUNTER"
					let a=a+2
					let LEFT-=1
					let b=b+1
				done	
				a=2
				while [ "$RIGHT" != "0" ]; do
					new=$(printf "%04d.JPG" ${a})
					ARRAY=( $(ls *.JPG | head -n 1) )
					jpegtran -rotate 90 -optimize -outfile "$PWD/renamed/${new}" ${ARRAY[0]}
					mv ${ARRAY[0]} "$PWD/.tmp"
					echo "Processing image ${b}/$COUNTER"
					let a=a+2
					let RIGHT-=1
					let b=b+1
				done
				echo
				echo "Cleaning up temporary files..."
				cd ".tmp"
				for i in *.JPG
					do cp $i "$1"
				done
				cd ..
				rm -R .tmp
				exit 0
			else
				echo "homer: No JPEG files found in the input directory."
				exit 1
			fi
		fi
	elif [[ ! "$3" == "-o" ]]; then
		echo "homer: \"$3\" is not a permitted option. See \"homer -h\" (or \"--help\")."
		exit 1
	elif [[ -z "$4" ]]; then
		echo "homer: Output directory not specified."
		exit 1
	elif [[ -d "$4" && "$4" == "$1" ]]; then
		echo "homer: The output folder cannot be the same as the input one."
		exit 1
	elif [[ ! `echo ${4:0:1} | grep "/"` == "" && -d "$4" ]]; then
		if [ "$(which jpegtran)" == "" ]; then
			echo >&2 "The script requires jpegtran, but jpegtran is not installed. Aborting."
			exit 1
		else
			cd "$1"
			shopt -s nocaseglob
			count=`ls -1 *.jpg 2>/dev/null | wc -l`
			if [ $count != 0 ]; then 
				echo
				echo "The images will be renamed and rotated starting from the LEFT-HAND PAGES, and "
				echo "will be saved into the \"$4\" folder."
				echo
				mkdir ".tmp"
				COUNTER=`ls *.JPG | wc -l`
				RIGHT=$(($COUNTER / 2))
				LEFT=$(($COUNTER / 2))
				a=1
				b=1
				while [ "$LEFT" != "0" ]; do
					new=$(printf "%04d.JPG" ${a})
					ARRAY=( $(ls *.JPG | head -n 1) ) 
					jpegtran -rotate 270 -optimize -outfile "$4/${new}" ${ARRAY[0]}
					mv ${ARRAY[0]} "$1/.tmp"
					echo "Processing image ${b}/$COUNTER"
					let a=a+2
					let LEFT-=1
					let b=b+1
				done	
				a=2
				while [ "$RIGHT" != "0" ]; do
					new=$(printf "%04d.JPG" ${a})
					ARRAY=( $(ls *.JPG | head -n 1) )
					jpegtran -rotate 90 -optimize -outfile "$4/${new}" ${ARRAY[0]}
					mv ${ARRAY[0]} "$1/.tmp"
					echo "Processing image ${b}/$COUNTER"
					let a=a+2
					let RIGHT-=1
					let b=b+1
				done
				echo
				echo "Cleaning up temporary files..."
				cd ".tmp"
				for i in *.JPG
					do cp $i "$1"
				done
				cd ..
				rm -R .tmp
				exit 0
			else
				echo "homer: No JPEG files found in the input directory."
				exit 1
			fi
		fi
	elif [[ ! `echo ${4:0:1} | grep "/"` == "" && -d `dirname "$4"` ]]; then
		if [ "$(which jpegtran)" == "" ]; then
			echo >&2 "The script requires jpegtran, but jpegtran is not installed. Aborting."
			exit 1
		else
			cd "$1"
			shopt -s nocaseglob
			count=`ls -1 *.jpg 2>/dev/null | wc -l`
			if [ $count != 0 ]; then 
				echo
				echo "The images will be renamed and rotated starting from the LEFT-HAND PAGES, and "
				echo "will be saved into the \"$4\" folder."
				echo
				mkdir "$4"
				mkdir ".tmp"
				COUNTER=`ls *.JPG | wc -l`
				RIGHT=$(($COUNTER / 2))
				LEFT=$(($COUNTER / 2))
				a=1
				b=1
				while [ "$LEFT" != "0" ]; do
					new=$(printf "%04d.JPG" ${a})
					ARRAY=( $(ls *.JPG | head -n 1) ) 
					jpegtran -rotate 270 -optimize -outfile "$4/${new}" ${ARRAY[0]}
					mv ${ARRAY[0]} "$1/.tmp"
					echo "Processing image ${b}/$COUNTER"
					let a=a+2
					let LEFT-=1
					let b=b+1
				done	
				a=2
				while [ "$RIGHT" != "0" ]; do
					new=$(printf "%04d.JPG" ${a})
					ARRAY=( $(ls *.JPG | head -n 1) )
					jpegtran -rotate 90 -optimize -outfile "$4/${new}" ${ARRAY[0]}
					mv ${ARRAY[0]} "$1/.tmp"
					echo "Processing image ${b}/$COUNTER"
					let a=a+2
					let RIGHT-=1
					let b=b+1
				done
				echo
				echo "Cleaning up temporary files..."
				cd ".tmp"
				for i in *.JPG
					do cp $i "$1"
				done
				cd ..
				rm -R .tmp
				exit 0
			else
				echo "homer: No JPEG files found in the input directory."
				exit 1
			fi
		fi
	elif [[ `echo ${4:0:1} | grep "/"` == "" && -d `dirname "$4"` ]]; then
		currentdir=$(PWD)
		cd "$1"
		shopt -s nocaseglob
		count=`ls -1 *.jpg 2>/dev/null | wc -l`
		if [ $count != 0 ]; then
			if [[ ! -d "$currentdir/$4" ]]; then 
				mkdir "$currentdir/$4"
			elif [[ -d "$currentdir/$4" && "$currentdir/$4" == "$1" ]]; then
				echo "homer: The output folder cannot be the same as the input one."
				exit 1	
			fi
			echo
			echo "The images will be renamed and rotated starting from the LEFT-HAND PAGES, and "
			echo "will be saved into the \"$currentdir/$4\" folder."
			echo
			mkdir ".tmp"
			COUNTER=`ls *.JPG | wc -l`
			RIGHT=$(($COUNTER / 2))
			LEFT=$(($COUNTER / 2))
			a=1
			b=1
			while [ "$LEFT" != "0" ]; do
				new=$(printf "%04d.JPG" ${a})
				ARRAY=( $(ls *.JPG | head -n 1) ) 
				jpegtran -rotate 270 -optimize -outfile "$currentdir/$4/${new}" ${ARRAY[0]}
				mv ${ARRAY[0]} "$1/.tmp"
				echo "Processing image ${b}/$COUNTER"
				let a=a+2
				let LEFT-=1
				let b=b+1
			done	
			a=2
			while [ "$RIGHT" != "0" ]; do
				new=$(printf "%04d.JPG" ${a})
				ARRAY=( $(ls *.JPG | head -n 1) )
				jpegtran -rotate 90 -optimize -outfile "$currentdir/$4/${new}" ${ARRAY[0]}
				mv ${ARRAY[0]} "$1/.tmp"
				echo "Processing image ${b}/$COUNTER"
				let a=a+2
				let RIGHT-=1
				let b=b+1
			done
			echo
			echo "Cleaning up temporary files..."
			cd ".tmp"
			for i in *.JPG
				do cp $i "$1"
			done
			cd ..
			rm -R .tmp
			exit 0
		else
			echo "homer: No JPEG files found in the input directory."
			exit 1
		fi
	elif [[ ! -d `dirname "$4"` ]]; then
		echo "homer: \"`dirname "$4"`\": no such folder"
		exit 1
	fi	
elif [[ "$2" == "-l" || "$2" == "--lang" ]]; then
	if [ "$(which tesseract)" == "" ]; then
		echo >&2 "The script requires Tesseract OCR, which is not installed. Aborting."
		exit 1
	else
		if [[ -z "$3" ]]; then
			echo "homer: OCR language not specified. Type 'homer -l' (or '--lang') to view the complete list of Tesseract supported languages."
		else
			if [[ -z "$4" ]]; then
				currentdir=$(PWD)
				cd "$1"
				shopt -s nocaseglob
				count=`ls -1 *.tif 2>/dev/null | wc -l`
				if [ $count != 0 ]; then
					# Tests if $1 is in the array ($2 $3 $4 ...).
					is_in() {
						value=$1
						shift
						for i in "$@"; do
							[[ $i == $value ]] && return 0
						done
						return 1
					}
					ok=0
					ARRAY=(bul cat ces chi_sim chi_tra dan dan-frak nld eng fin fra deu deu-frak ell hun ind ita jpn kor lav lit nor pol por ron rus slk slv spa srp swe swe-frak ukr vie)
					if ! is_in "$3" "${ARRAY[@]}"; then
						echo "homer: \"$3\" is not a permitted value. Type 'homer -l' (or '--lang') to view the complete list of Tesseract supported languages." >&2
						exit 1
					else
						ok=1
					fi
					echo
					echo "Please wait while Tesseract is processing the files:"
					echo
					cd "$1"
					for img in *.tif
						do
						filename=${img%%.*}
						tesseract $img $filename -l $3 hocr 2>> tesseract-log.txt
						echo "   Processed $img"
					done
					echo
					echo "PDFbeads is now combining the images into a single PDF. Please wait..."
					pdfbeads --bg-compression JPG --output "$currentdir/out.pdf" *.tif &> pdfbeads-log.txt
					if [ ! -f "$currentdir/out.pdf" ]; then
						tail -1 pdfbeads-log.txt
						exit 1
					fi
					exit 0
				else
					echo "homer: No TIFF files found in the input directory."
					exit 1
				fi
			elif [[ "$4" == "-o" || "$4" == "--output" ]]; then
				if [[ -z "$5" ]]; then
					echo "homer: Output not specified."
					exit 1
				elif [[ ! -d `dirname "$5"` ]]; then
					echo "homer: `dirname "$5"`: No such folder."
					exit 1
				elif [[ `echo $5 | grep "/"` == "" && ( ${5:(-4)} == ".PDF" || ${5:(-4)} == ".pdf" ) ]]; then
					currentdir=$(PWD)
					cd "$1"
					shopt -s nocaseglob
					count=`ls -1 *.tif 2>/dev/null | wc -l`
					if [ $count != 0 ]; then
						# Tests if $1 is in the array ($2 $3 $4 ...).
						is_in() {
							value=$1
							shift
							for i in "$@"; do
								[[ $i == $value ]] && return 0
							done
							return 1
						}
						ok=0
						ARRAY=(bul cat ces chi_sim chi_tra dan dan-frak nld eng fin fra deu deu-frak ell hun ind ita jpn kor lav lit nor pol por ron rus slk slv spa srp swe swe-frak ukr vie)
						if ! is_in "$3" "${ARRAY[@]}"; then
							echo "homer: \"$3\" is not a permitted value. Type 'homer -l' (or '--lang') to view the complete list of Tesseract supported languages." >&2
							exit 1
						else
							ok=1
						fi
						echo
						echo "Please wait while Tesseract is processing the files:"
						echo
						cd "$1"
						for img in *.tif
							do
							filename=${img%%.*}
							tesseract $img $filename -l $3 hocr 2>> tesseract-log.txt
							echo "   Processed $img"
						done
						echo
						echo "PDFbeads is now combining the images into a single PDF. Please wait..."
						pdfbeads --bg-compression JPG --output "$currentdir/$5" *.tif &> pdfbeads-log.txt
						if [ ! -f "$currentdir/$5" ]; then
							tail -1 pdfbeads-log.txt
							exit 1
						fi
						exit 0
					else
						echo "homer: No TIFF files found in the input directory."
						exit 1
					fi
				elif [[ `echo $5 | grep "/"` == "" && ! ( ${5:(-4)} == ".PDF" || ${5:(-4)} == ".pdf" ) && -d $5 ]]; then
					currentdir=$(PWD)
					cd "$1"
					shopt -s nocaseglob
					count=`ls -1 *.tif 2>/dev/null | wc -l`
					if [ $count != 0 ]; then
						# Tests if $1 is in the array ($2 $3 $4 ...).
						is_in() {
							value=$1
							shift
							for i in "$@"; do
								[[ $i == $value ]] && return 0
							done
							return 1
						}
						ok=0
						ARRAY=(bul cat ces chi_sim chi_tra dan dan-frak nld eng fin fra deu deu-frak ell hun ind ita jpn kor lav lit nor pol por ron rus slk slv spa srp swe swe-frak ukr vie)
						if ! is_in "$3" "${ARRAY[@]}"; then
							echo "homer: \"$3\" is not a permitted value. Type 'homer -l' (or '--lang') to view the complete list of Tesseract supported languages." >&2
							exit 1
						else
							ok=1
						fi
						echo
						echo "Please wait while Tesseract is processing the files:"
						echo
						cd "$1"
						for img in *.tif
							do
							filename=${img%%.*}
							tesseract $img $filename -l $3 hocr 2>> tesseract-log.txt
							echo "   Processed $img"
						done
						echo
						echo "PDFbeads is now combining the images into a single PDF. Please wait..."
						pdfbeads --bg-compression JPG --output "$currentdir/$5/out.pdf" *.tif &> pdfbeads-log.txt
						if [ ! -f "$currentdir/$5/out.pdf" ]; then
							tail -1 pdfbeads-log.txt
							exit 1
						fi
					else
						echo "homer: No TIFF files found in the input directory."
						exit 1
					fi
					exit 0
				elif [[ `echo $5 | grep "/"` == "" && ! ( ${5:(-4)} == ".PDF" || ${5:(-4)} == ".pdf" ) && ! -d $5 ]]; then
					currentdir=$(PWD)
					cd "$1"
					shopt -s nocaseglob
					count=`ls -1 *.tif 2>/dev/null | wc -l`
					if [ $count != 0 ]; then
						# Tests if $1 is in the array ($2 $3 $4 ...).
						is_in() {
							value=$1
							shift
							for i in "$@"; do
								[[ $i == $value ]] && return 0
							done
							return 1
						}
						ok=0
						ARRAY=(bul cat ces chi_sim chi_tra dan dan-frak nld eng fin fra deu deu-frak ell hun ind ita jpn kor lav lit nor pol por ron rus slk slv spa srp swe swe-frak ukr vie)
						if ! is_in "$3" "${ARRAY[@]}"; then
							echo "homer: \"$3\" is not a permitted value. Type 'homer -l' (or '--lang') to view the complete list of Tesseract supported languages." >&2
							exit 1
						else
							ok=1
						fi
						echo
						echo "Please wait while Tesseract is processing the files:"
						echo
						cd "$1"
						for img in *.tif
							do
							filename=${img%%.*}
							tesseract $img $filename -l $3 hocr 2>> tesseract-log.txt
							echo "   Processed $img"
						done
						echo
						echo "PDFbeads is now combining the images into a single PDF. Please wait..."
						pdfbeads --bg-compression JPG --output "$currentdir/$5.pdf" *.tif &> pdfbeads-log.txt
						if [ ! -f "$currentdir/$5.pdf" ]; then
							tail -1 pdfbeads-log.txt
							exit 1
						fi
						exit 0
					else
						echo "homer: No TIFF files found in the input directory."
						exit 1
					fi
				elif [[ `echo ${5:0:1} | grep "/"` == "" && ! `echo $5 | grep "/"` == "" && ! ( ${5:(-4)} == ".PDF" || ${5:(-4)} == ".pdf" )  && -d $5 ]]; then
					currentdir=$(PWD)
					cd "$1"
					shopt -s nocaseglob
					count=`ls -1 *.tif 2>/dev/null | wc -l`
					if [ $count != 0 ]; then
						# Tests if $1 is in the array ($2 $3 $4 ...).
						is_in() {
							value=$1
							shift
							for i in "$@"; do
								[[ $i == $value ]] && return 0
							done
							return 1
						}
						ok=0
						ARRAY=(bul cat ces chi_sim chi_tra dan dan-frak nld eng fin fra deu deu-frak ell hun ind ita jpn kor lav lit nor pol por ron rus slk slv spa srp swe swe-frak ukr vie)
						if ! is_in "$3" "${ARRAY[@]}"; then
							echo "homer: \"$3\" is not a permitted value. Type 'homer -l' (or '--lang') to view the complete list of Tesseract supported languages." >&2
							exit 1
						else
							ok=1
						fi
						echo
						echo "Please wait while Tesseract is processing the files:"
						echo
						cd "$1"
						for img in *.tif
							do
							filename=${img%%.*}
							tesseract $img $filename -l $3 hocr 2>> tesseract-log.txt
							echo "   Processed $img"
						done
						echo
						echo "PDFbeads is now combining the images into a single PDF. Please wait..."
						pdfbeads --bg-compression JPG --output "$currentdir/$5/out.pdf" *.tif &> pdfbeads-log.txt
						if [ ! -f "$currentdir/$5/out.pdf" ]; then
							tail -1 pdfbeads-log.txt
							exit 1
						fi
						exit 0
					else
						echo "homer: No TIFF files found in the input directory."
						exit 1
					fi
				elif [[ `echo ${5:0:1} | grep "/"` == "" && ! `echo $5 | grep "/"` == "" && ! ( ${5:(-4)} == ".PDF" || ${5:(-4)} == ".pdf" )  && ! -d $5 ]]; then
					currentdir=$(PWD)
					cd "$1"
					shopt -s nocaseglob
					count=`ls -1 *.tif 2>/dev/null | wc -l`
					if [ $count != 0 ]; then
						# Tests if $1 is in the array ($2 $3 $4 ...).
						is_in() {
							value=$1
							shift
							for i in "$@"; do
								[[ $i == $value ]] && return 0
							done
							return 1
						}
						ok=0
						ARRAY=(bul cat ces chi_sim chi_tra dan dan-frak nld eng fin fra deu deu-frak ell hun ind ita jpn kor lav lit nor pol por ron rus slk slv spa srp swe swe-frak ukr vie)
						if ! is_in "$3" "${ARRAY[@]}"; then
							echo "homer: \"$3\" is not a permitted value. Type 'homer -l' (or '--lang') to view the complete list of Tesseract supported languages." >&2
							exit 1
						else
							ok=1
						fi
						echo
						echo "Please wait while Tesseract is processing the files:"
						echo
						cd "$1"
						for img in *.tif
							do
							filename=${img%%.*}
							tesseract $img $filename -l $3 hocr 2>> tesseract-log.txt
							echo "   Processed $img"
						done
						echo
						echo "PDFbeads is now combining the images into a single PDF. Please wait..."
						pdfbeads --bg-compression JPG --output "$currentdir/$5.pdf" *.tif &> pdfbeads-log.txt
						if [ ! -f "$currentdir/$5.pdf" ]; then
							tail -1 pdfbeads-log.txt
							exit 1
						fi
						exit 0
					else
						echo "homer: No TIFF files found in the input directory."
						exit 1
					fi	
				elif [[ `echo ${5:0:1} | grep "/"` == "" && ! `echo $5 | grep "/"` == "" && ( ${5:(-4)} == ".PDF" || ${5:(-4)} == ".pdf" ) ]]; then
					currentdir=$(PWD)
					cd "$1"
					shopt -s nocaseglob
					count=`ls -1 *.tif 2>/dev/null | wc -l`
					if [ $count != 0 ]; then
						# Tests if $1 is in the array ($2 $3 $4 ...).
						is_in() {
							value=$1
							shift
							for i in "$@"; do
								[[ $i == $value ]] && return 0
							done
							return 1
						}
						ok=0
						ARRAY=(bul cat ces chi_sim chi_tra dan dan-frak nld eng fin fra deu deu-frak ell hun ind ita jpn kor lav lit nor pol por ron rus slk slv spa srp swe swe-frak ukr vie)
						if ! is_in "$3" "${ARRAY[@]}"; then
							echo "homer: \"$3\" is not a permitted value. Type 'homer -l' (or '--lang') to view the complete list of Tesseract supported languages." >&2
							exit 1
						else
							ok=1
						fi
						echo
						echo "Please wait while Tesseract is processing the files:"
						echo
						cd "$1"
						for img in *.tif
							do
							filename=${img%%.*}
							tesseract $img $filename -l $3 hocr 2>> tesseract-log.txt
							echo "   Processed $img"
						done
						echo
						echo "PDFbeads is now combining the images into a single PDF. Please wait..."
						pdfbeads --bg-compression JPG --output "$currentdir/$5" *.tif &> pdfbeads-log.txt
						if [ ! -f "$currentdir/$5" ]; then
							tail -1 pdfbeads-log.txt
							exit 1
						fi
						exit 0
					else
						echo "homer: No TIFF files found in the input directory."
						exit 1
					fi
				elif [[ ! `echo ${5:0:1} | grep "/"` == "" && ( ${5:(-4)} == ".PDF" || ${5:(-4)} == ".pdf" ) ]]; then
					cd "$1"
					shopt -s nocaseglob
					count=`ls -1 *.tif 2>/dev/null | wc -l`
					if [ $count != 0 ]; then
						# Tests if $1 is in the array ($2 $3 $4 ...).
						is_in() {
							value=$1
							shift
							for i in "$@"; do
								[[ $i == $value ]] && return 0
							done
							return 1
						}
						ok=0
						ARRAY=(bul cat ces chi_sim chi_tra dan dan-frak nld eng fin fra deu deu-frak ell hun ind ita jpn kor lav lit nor pol por ron rus slk slv spa srp swe swe-frak ukr vie)
						if ! is_in "$3" "${ARRAY[@]}"; then
							echo "homer: \"$3\" is not a permitted value. Type 'homer -l' (or '--lang') to view the complete list of Tesseract supported languages." >&2
							exit 1
						else
							ok=1
						fi
						echo
						echo "Please wait while Tesseract is processing the files:"
						echo
						cd "$1"
						for img in *.tif
							do
							filename=${img%%.*}
							tesseract $img $filename -l $3 hocr 2>> tesseract-log.txt
							echo "   Processed $img"
						done
						echo
						echo "PDFbeads is now combining the images into a single PDF. Please wait..."
						pdfbeads --bg-compression JPG --output "$5" *.tif &> pdfbeads-log.txt
						if [ ! -f "$5" ]; then
							tail -1 pdfbeads-log.txt
							exit 1
						fi
						exit 0
					else
						echo "homer: No TIFF files found in the input directory."
						exit 1
					fi
				elif [[ ! `echo ${5:0:1} | grep "/"` == "" && ! ( ${5:(-4)} == ".PDF" || ${5:(-4)} == ".pdf" ) && -d $5 ]]; then
					cd "$1"
					shopt -s nocaseglob
					count=`ls -1 *.tif 2>/dev/null | wc -l`
					if [ $count != 0 ]; then
						# Tests if $1 is in the array ($2 $3 $4 ...).
						is_in() {
							value=$1
							shift
							for i in "$@"; do
								[[ $i == $value ]] && return 0
							done
							return 1
						}
						ok=0
						ARRAY=(bul cat ces chi_sim chi_tra dan dan-frak nld eng fin fra deu deu-frak ell hun ind ita jpn kor lav lit nor pol por ron rus slk slv spa srp swe swe-frak ukr vie)
						if ! is_in "$3" "${ARRAY[@]}"; then
							echo "homer: \"$3\" is not a permitted value. Type 'homer -l' (or '--lang') to view the complete list of Tesseract supported languages." >&2
							exit 1
						else
							ok=1
						fi
						echo
						echo "Please wait while Tesseract is processing the files:"
						echo
						cd "$1"
						for img in *.tif
							do
							filename=${img%%.*}
							tesseract $img $filename -l $3 hocr 2>> tesseract-log.txt
							echo "   Processed $img"
						done
						echo
						echo "PDFbeads is now combining the images into a single PDF. Please wait..."
						pdfbeads --bg-compression JPG --output "$5/out.pdf" *.tif &> pdfbeads-log.txt
						if [ ! -f "$5/out.pdf" ]; then
							tail -1 pdfbeads-log.txt
							exit 1
						fi
						exit 0
					else
						echo "homer: No TIFF files found in the input directory."
						exit 1
					fi
				elif [[ ! `echo ${5:0:1} | grep "/"` == "" && ! ( ${5:(-4)} == ".PDF" || ${5:(-4)} == ".pdf" ) && ! -d $5 ]]; then
					cd "$1"
					shopt -s nocaseglob
					count=`ls -1 *.tif 2>/dev/null | wc -l`
					if [ $count != 0 ]; then
						# Tests if $1 is in the array ($2 $3 $4 ...).
						is_in() {
							value=$1
							shift
							for i in "$@"; do
								[[ $i == $value ]] && return 0
							done
							return 1
						}
						ok=0
						ARRAY=(bul cat ces chi_sim chi_tra dan dan-frak nld eng fin fra deu deu-frak ell hun ind ita jpn kor lav lit nor pol por ron rus slk slv spa srp swe swe-frak ukr vie)
						if ! is_in "$3" "${ARRAY[@]}"; then
							echo "homer: \"$3\" is not a permitted value. Type 'homer -l' (or '--lang') to view the complete list of Tesseract supported languages." >&2
							exit 1
						else
							ok=1
						fi
						echo
						echo "Please wait while Tesseract is processing the files:"
						echo
						cd "$1"
						for img in *.tif
							do
							filename=${img%%.*}
							tesseract $img $filename -l $3 hocr 2>> tesseract-log.txt
							echo "   Processed $img"
						done
						echo
						echo "PDFbeads is now combining the images into a single PDF. Please wait..."
						pdfbeads --bg-compression JPG --output "$5.pdf" *.tif &> pdfbeads-log.txt
						if [ ! -f "$5.pdf" ]; then
							tail -1 pdfbeads-log.txt
							exit 1
						fi
						exit 0
					else
						echo "homer: No TIFF files found in the input directory."
						exit 1
					fi
				fi
			elif [[ ! "$4" == "-o" ]]; then
					echo "homer: \"$4\" is not a permitted option. See \"homer -h\" (or \"--help\")."
					exit 1
			fi
		fi	
	fi
elif [[ ! "$2" == "-r" && ! "$2" == "-R" && ! "$2" == "-L" && ! "$2" == "l" ]]; then
	echo "homer: \"$2\" is not a permitted option. See \"homer -h\" (or \"--help\")." 
fi