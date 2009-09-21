EXTENSION="$1"

CURRENTDIR=`dirname $TM_FILEPATH`

if [ -z $TM_PROJECT_DIRECTORY ]; then
  
  L=$((${#CURRENTDIR}+1))

  MENUITEMS=$(find -s "$CURRENTDIR" -name "*$EXTENSION" | perl -pe "s/^.{$L}(.*?)$/{title=\"\$1\";}/" | paste -sd ',' -)
  [[ -z $MENUITEMS ]] && exit 200
  "$DIALOG" -u -p "{menuItems=($MENUITEMS);}" | perl -e 'undef $/;$a=<>;$a=~m/<key>title(.|\n)+?<string>(.*?)</;print $2;'

else

  FILES=$(find -s "$TM_PROJECT_DIRECTORY" -name "*$EXTENSION")

  FILES=$(echo "$FILES" | perl -pe "s!$CURRENTDIR/!!")

  if [ "$CURRENTDIR" != "$TM_PROJECT_DIRECTORY" ]; then
    CURRENTDIR=$(dirname $CURRENTDIR)
    REPLACE=""
    while [ "$CURRENTDIR" != "$TM_PROJECT_DIRECTORY" ]; do
      REPLACE="$REPLACE../"
      FILES=$(echo "$FILES" | perl -pe "s!$CURRENTDIR/!$REPLACE!")
      CURRENTDIR=$(dirname $CURRENTDIR)
    done
    REPLACE="$REPLACE../"
    FILES=$(echo "$FILES" | perl -pe "s!$CURRENTDIR/!$REPLACE!")
  fi

  MENUITEMS=$(echo "$FILES" | perl -pe "s/^(.*?)$/{title=\"\$1\";}/" | paste -sd ',' -)
  [[ -z $MENUITEMS ]] && exit 200
  "$DIALOG" -u -p "{menuItems=($MENUITEMS);}" | perl -e 'undef $/;$a=<>;$a=~m/<key>title(.|\n)+?<string>(.*?)</;print $2;'


fi