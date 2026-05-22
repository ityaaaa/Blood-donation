from flask import Flask, render_template, request
import mysql.connector

app = Flask(__name__, template_folder='.')

# MySQL Connection
db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="munni@2006",
    database="blood_donation_system"
)

@app.route('/', methods=['GET', 'POST'])
def home():

    donors = []

    selected_group = ""

    if request.method == 'POST':

        selected_group = request.form['blood_group']

        cursor = db.cursor(dictionary=True)
        query = """
SELECT
    d.full_name,
    d.phone_number,
    bt_donor.blood_group,

    ROUND(
        SQRT(
            POW(d.latitude - 12.9716, 2) +
            POW(d.longitude - 77.5946, 2)
        ),
        4
    ) AS distance

FROM donors d

JOIN blood_types bt_donor
    ON d.blood_type_id = bt_donor.blood_type_id

JOIN compatibility_rules cr
    ON d.blood_type_id = cr.donor_type_id

JOIN blood_types bt_needed
    ON cr.recipient_type_id = bt_needed.blood_type_id

WHERE bt_needed.blood_group = %s

AND d.health_status = 'Healthy'

AND d.is_available = TRUE

AND DATEDIFF(CURDATE(), d.last_donation_date) > 56

ORDER BY distance ASC
"""
        cursor.execute(query, (selected_group,))

        donors = cursor.fetchall()

    return render_template('index.html', donors=donors, selected_group=selected_group)


if __name__ == '__main__':
    app.run(debug=True)