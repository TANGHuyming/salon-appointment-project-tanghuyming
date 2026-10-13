#!/bin/bash
PSQL="psql --username=postgres --dbname=salon --no-align --tuples-only -c"

function main_menu() {
  if [[ $1 ]] 
  then
    echo -e "~~~~~ MY SALON ~~~~~\n"
    echo -e "Welcome to My Salon, how can I help you?\n"
  fi

  $PSQL "SELECT service_id, name FROM services ORDER BY service_id" | while IFS="|" read ID NAME
  do
    echo "$ID) $NAME"
  done
  read SERVICE_ID_SELECTED

  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
  if [[ -z $SERVICE_NAME ]] 
  then
    echo -e "\nI could not find that service. What would you like today?"
    main_menu 1
  else
    schedule_appointment $SERVICE_ID_SELECTED $SERVICE_NAME
  fi
}

function schedule_appointment() {
  SERVICE_ID=$1
  SERVICE_NAME=$2

  echo "What's your phone number?"
  read CUSTOMER_PHONE

  if [[ -z $($PSQL "SELECT * FROM customers WHERE phone = '$CUSTOMER_PHONE'") ]]
  then
    echo "I don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME
    CUSTOMER_INSERTED=$($PSQL "INSERT INTO customers (name, phone) VALUES ('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
    echo "Saved a new customer record: $CUSTOMER_NAME | $CUSTOMER_PHONE"
  fi

  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
  CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")

  echo "What time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
  read SERVICE_TIME

  SERVICE_INSERTED=$($PSQL "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID, '$SERVICE_TIME')")

  if [[ $SERVICE_INSERTED == "INSERT 0 1" ]]
  then
    echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
  fi
}

main_menu
