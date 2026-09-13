from flask import Flask, render_template, request, redirect, url_for
import mysql.connector

app = Flask(__name__, template_folder='templates')

# Central Relational Database Connection
db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="munni@2006",
    database="blood_donation_system"
)

@app.route('/')
def index():
    """Renders the comprehensive landing portal for BloodDon"""
    return render_template('index.html', active_page='index')

@app.route('/hospital', methods=['GET', 'POST'])
def hospital_dashboard():
    donors = []
    selected_group = ""

    if request.method == 'POST':
        form_type = request.form.get('form_type')
        user_lat = float(request.form.get('lat', 12.9716))
        user_lng = float(request.form.get('lng', 77.5946))

        # ACTION A: QUERY COMPATIBLE DONORS MATRIX
        if form_type == 'search_donors':
            selected_group = request.form['blood_group']
            cursor = db.cursor(dictionary=True)
            query = """
                SELECT d.full_name, d.phone_number, d.latitude, d.longitude, bt_donor.blood_group,
                ROUND(SQRT(POW(d.latitude - %s, 2) + POW(d.longitude - %s, 2)) * 111.12, 2) AS distance
                FROM donors d
                JOIN blood_types bt_donor ON d.blood_type_id = bt_donor.blood_type_id
                JOIN compatibility_rules cr ON d.blood_type_id = cr.donor_type_id
                JOIN blood_types bt_needed ON cr.recipient_type_id = bt_needed.blood_type_id
                WHERE bt_needed.blood_group = %s AND d.health_status = 'Healthy' AND d.is_available = TRUE
                AND DATEDIFF(CURDATE(), d.last_donation_date) > 56
                ORDER BY distance ASC
            """
            cursor.execute(query, (user_lat, user_lng, selected_group))
            donors = cursor.fetchall()
            cursor.close()

        # ACTION B: LOG NEW HOSPITAL BROADCAST EMERGENCY ALERT
        elif form_type == 'broadcast_alert':
            hospital_name = request.form['hospital_name']
            needed_blood_type = int(request.form['needed_blood_type'])
            units_needed = int(request.form['units_needed'])
            urgency_level = request.form['urgency_level']

            cursor = db.cursor()
            query = """
                INSERT INTO emergency_requests (hospital_name, needed_blood_type, units_needed, urgency_level, latitude, longitude)
                VALUES (%s, %s, %s, %s, %s, %s)
            """
            cursor.execute(query, (hospital_name, needed_blood_type, units_needed, urgency_level, user_lat, user_lng))
            db.commit()
            cursor.close()
            return redirect(url_for('hospital_dashboard'))

    return render_template('hospital_dashboard.html', donors=donors, selected_group=selected_group, active_page='hospital')


@app.route('/donor', methods=['GET', 'POST'])
def donor_dashboard():
    cursor = db.cursor(dictionary=True)

    if request.method == 'POST':
        form_type = request.form.get('form_type')
        
        # ACTION: ONBOARD NEW FIELD DONOR RECORD
        if form_type == 'register_donor':
            full_name = request.form['full_name']
            phone_number = request.form['phone_number']
            blood_type_id = int(request.form['blood_type_id'])
            last_donation = request.form['last_donation_date']
            lat = float(request.form.get('lat', 12.9716))
            lng = float(request.form.get('lng', 77.5946))

            ins_cursor = db.cursor()
            query = """
                INSERT INTO donors (full_name, phone_number, blood_type_id, latitude, longitude, health_status, last_donation_date, is_available)
                VALUES (%s, %s, %s, %s, %s, 'Healthy', %s, TRUE)
            """
            ins_cursor.execute(query, (full_name, phone_number, blood_type_id, lat, lng, last_donation))
            db.commit()
            ins_cursor.close()
            return redirect(url_for('donor_dashboard'))

    # ALWAYS FETCH RECENT BROADCAST ALERTS FOR THE DONOR'S LOG VIEW
    query = """
        SELECT er.hospital_name, er.units_needed, er.urgency_level, bt.blood_group AS needed_blood
        FROM emergency_requests er
        JOIN blood_types bt ON er.needed_blood_type = bt.blood_type_id
        ORDER BY er.request_time DESC LIMIT 10
    """
    cursor.execute(query)
    requests = cursor.fetchall()
    cursor.close()

    return render_template('donor_dashboard.html', requests=requests, active_page='donor')


if __name__ == '__main__':
    app.run(debug=True)