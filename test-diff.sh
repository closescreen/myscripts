#!/usr/bin/env bash

# для указанных двух веток
# для указанной подстроки (perl regexp), например 
# 'create_service_record|SRS::Shopcart::reset_additional_data|SRS::Service::add'
# ищет файлы тестов *.t с упоминаниями этих методов
# в каждой ветке запускает тесты, записывая вывод в файлы
# сравнивает пары файлов между собой

if [[ -z "$@" ]]; then # если нет параметров

  # интерактивно спрашиваем первую ветку
  echo "'Right' branch: [master]:"; read br1
  [[ -z "$br1" ]] && br1="master"
  [[ -z "$br1" ]] && echo "empty branch-1 name!">&2 && exit 1

  # печать, списка веток, для лучшей ориентации:
  git branch -v || exit 1
  
  # второй веткой выбираем (по умолчанию) текущую ветку:
  def2=`git branch -v | awk '$1=="*"{print $2}'`
  # спрашиваем вторую ветку:
  echo -e "\nBranch for checking [$def2]:"; read br2
  [[ -z "$br2" ]] && br2="$def2"
  [[ -z "$br2" ]] && echo "empty branch-2 name!">&2 && exit 1

  # спрашиваем подстроку:
  echo "Substring to find in test files *.t :"; read substring
  [[ -z "$substring" ]] && echo "substring !">&2 && exit 1
  
  # спрашиваем куда класть результаты:
  def4="$HOME/regru/my_test_results"
  echo "Where to write test results: [$def4]"; read results_folder;
  [[ -z "$results_folder" ]] && results_folder=$def4

else
  # из параметров: br1 br2 подстрока
  br1=${1:? branch 1!}
  br2=${2:? branch 2!}
  substring=${3:? substring to find!}
  results_folder=${4:-"$def4"}
fi

tt=$( grep -r -i -P "$substring" --include=*.t | awk -F\: '{print $1}' | sort | uniq )

for br in "$br1" "$br2"; do 
  [[ ! -d "$results_folder/$br" ]] && echo "creating $results_folder/$br ..." >&2 && mkdir -p "$results_folder/$br"
  git checkout "$br" || break; 
  for t in $tt; do 
	(
	  echo "========================= $t ========================="; 
	  perl $t;
	  echo "-----------------------------------------------------" ) 2>&1 | tee "$results_folder/$br/`basename $t`.result" ;
  done;
done

# сравнение результатов:
for t in $tt; do
  $t_result1="$results_folder/$br1/`basename $t`.result"
  $t_result2="$results_folder/$br2/`basename $t`.result"
  echo -n "Compare $t_result1 <-> $t_result2 ...">&2
  ( diff -d "$t_result1" "$t_result2" && echo "ok">&2 ) || echo " !!!!!!!!!!!!! DIFFERENCE !!!!!!!!!!! ( $t_result1 <-> $t_result2 )">&2
done

echo "Done. Look test results in $results_folder"

