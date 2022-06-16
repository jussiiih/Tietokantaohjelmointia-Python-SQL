import sqlite3

db = sqlite3.connect("bikes.db")
db.isolation_level = None

def distance_of_user(user):
    yhteismatka = db.execute("SELECT SUM(T.distance) FROM Trips T LEFT JOIN Users U ON T.user_id=U.id WHERE U.name=?", [user]).fetchone()
    return yhteismatka[0]

def speed_of_user(user):
    keskinopeus = db.execute("SELECT ((SUM(T.distance))/1000.)/((SUM(T.duration))/60.) FROM Trips T LEFT JOIN Users U ON T.user_id=U.id WHERE U.name=?", [user]).fetchone()
    oikeatarkkuus = ('%.2f'%(keskinopeus[0]))
    return oikeatarkkuus

def duration_in_each_city(day):
    ajat= db.execute("SELECT C.name, SUM(T.duration) FROM Trips T LEFT JOIN Stops S ON T.from_id=S.id LEFT JOIN Cities C ON S.city_id=C.id WHERE T.day=? GROUP BY C.name", [day]).fetchall()
    return ajat

def users_in_city(city):
    aika = db.execute("SELECT COUNT(DISTINCT T.user_id) FROM Trips T LEFT JOIN Stops S ON T.from_id=S.id LEFT JOIN Cities C ON C.id=S.city_id WHERE C.name=?", [city]).fetchone()
    return aika[0]

def trips_on_each_day(city):
    matkat=db.execute(" SELECT COUNT(T.user_id), T.day FROM Trips T LEFT JOIN Stops S ON T.from_id=S.id LEFT JOIN Cities C ON C.id=S.city_id WHERE C.name=? GROUP By T.day", [city]).fetchall()
    return matkat

def most_popular_start(city):
    tulos = db.execute("SELECT S.name, COUNT (T.from_id) FROM Trips T LEFT JOIN Stops S ON T.from_id=S.id LEFT JOIN Cities C ON C.id=S.city_id WHERE C.name=? GROUP BY T.from_id ORDER BY (COUNT (T.from_id)) DESC LIMIT 1", [city]).fetchall()
    return tulos
