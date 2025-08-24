package main

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/go-sql-driver/mysql"
)

// db is the global database connection handle.
var db *sql.DB

// DBConnectAndPing establishes a connection to the MySQL database
// using environment variables and the provided password.
// It returns an error if the connection or ping fails.
func DBConnectAndPing(db_password string) error {
	log.Print("Inside DBConnectAndPing func")

	// Capture connection properties
	cfg := mysql.Config{
		User: os.Getenv("DB_USER"),
		// Passwd: os.Getenv("DB_PASS"),
		Passwd: db_password,
		Net:    "tcp",
		// Addr:   "127.0.0.1:3306",
		Addr:   fmt.Sprintf("%v:%v", os.Getenv("HOST"), os.Getenv("PORT")),
		DBName: os.Getenv("DB_NAME"),
	}

	// Get a database handle.
	var err error
	db, err = sql.Open("mysql", cfg.FormatDSN())
	if err != nil {
		return fmt.Errorf("DB Connection error: %v", err)
	}

	// Check if db is connected
	if err := db.Ping(); err != nil {
		return fmt.Errorf("DB Connection error: %v", err)
	}
	log.Print("DB Connected")
	return nil

}

// GetAllMovies_DB returns all movies from the database.
func GetAllMovies_DB() ([]Movie, error) {
	log.Print("Inside GetAllMovies_DB func")

	var movies []Movie

	rows, err := db.Query("SELECT * FROM movie_details")
	if err != nil {
		return nil, fmt.Errorf("GetAllMovies_DB error: %v", err)
	}

	defer rows.Close()

	for rows.Next() {
		var movie Movie

		if err := rows.Scan(&movie.MovieId, &movie.Title, &movie.ReleaseYear, &movie.Genre, &movie.CoverUrl, &movie.GeneratedSummary); err != nil {
			return nil, fmt.Errorf("GetAllMovies_DB error: %v", err)
		}

		movies = append(movies, movie)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("GetAllMovies_DB error: %v", err)
	}

	return movies, nil
}

// GetMoviesByYear_DB returns all movies released in the given year.
func GetMoviesByYear_DB(year string) ([]Movie, error) {
	log.Print("Inside GetMoviesByYear_DB func")

	var movies []Movie

	rows, err := db.Query("SELECT * FROM movie_details WHERE releaseYear = ?", year)
	if err != nil {
		return nil, fmt.Errorf("GetMoviesByYear_DB error: %v", err)
	}

	defer rows.Close()

	for rows.Next() {
		var movie Movie

		if err := rows.Scan(&movie.MovieId, &movie.Title, &movie.ReleaseYear, &movie.Genre, &movie.CoverUrl, &movie.GeneratedSummary); err != nil {
			return nil, fmt.Errorf("GetMoviesByYear_DB error: %v", err)
		}

		movies = append(movies, movie)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("GetMoviesByYear_DB error: %v", err)
	}

	return movies, nil
}

// GetMovieById_DB returns a movie by its ID.
// It returns an error if the movie is not found.
func GetMovieById_DB(movieId string) (Movie, error) {
	log.Print("Inside GetMovieById_DB func")

	var movie Movie
	row := db.QueryRow("SELECT * FROM movie_details WHERE movieId = ?", movieId)

	if err := row.Scan(&movie.MovieId, &movie.Title, &movie.ReleaseYear, &movie.Genre, &movie.CoverUrl, &movie.GeneratedSummary); err != nil {
		if err == sql.ErrNoRows {
			log.Printf("GetMovieById_DB error: %v", err)
			return movie, fmt.Errorf("No movie found with given movieId")
		}
		return movie, fmt.Errorf("GetMovieById_DB error: %v", err)
	}

	return movie, nil
}

// GetMovieSummary_DB returns the summary of a movie by its ID.
// If no summary exists, it generates one using Bedrock AI and saves it.
func GetMovieSummary_DB(movieId string) (string, error) {
	log.Print("Inside GetMovieSummary_DB func")

	var movie Movie
	row := db.QueryRow("SELECT * FROM movie_details WHERE movieId = ?", movieId)

	if err := row.Scan(&movie.MovieId, &movie.Title, &movie.ReleaseYear, &movie.Genre, &movie.CoverUrl, &movie.GeneratedSummary); err != nil {
		if err == sql.ErrNoRows {
			log.Printf("GetMovieById_DB error: %v", err)
			return "", fmt.Errorf("No movie found with given movieId")
		}
		return "", fmt.Errorf("GetMovieById_DB error: %v", err)
	}

	if movie.GeneratedSummary == nil || *movie.GeneratedSummary == "" {
		log.Print("No summary available. Generate a summary.")

		// Call the bedrock service to generate the movie summary
		movieSummary, err := GenerateMovieSummary(movie)
		if err != nil {
			log.Print(err)
			return "", err
		}

		// Save the summary for next time fetch for the movie
		if err := UpdateMovieSummary_DB(movie.MovieId, movieSummary); err != nil {
			log.Print(err)
			return "", err
		}

		return movieSummary, nil
	}

	return *movie.GeneratedSummary, nil
}

// UpdateMovieSummary_DB updates the generated summary for a movie.
func UpdateMovieSummary_DB(movieId int, summary string) error {
	log.Print("Inside UpdateMovieSummary_DB func")

	_, err := db.Exec("UPDATE movie_details SET generatedSummary=? WHERE movieId=?", summary, movieId)

	if err != nil {
		return fmt.Errorf("UpdateMovieSummary_DB error: %v", err)
	}

	log.Print("Movie summary updated")
	return nil
}

// GetMovieByTitle_DB returns a movie by its title (case-insensitive).
// It returns an error if the movie is not found.
func GetMovieByTitle_DB(title string) (Movie, error) {

	var movie Movie
	row := db.QueryRow("SELECT * FROM movie_details WHERE LOWER(TRIM(title)) = ?", strings.TrimSpace(strings.ToLower(title)))

	if err := row.Scan(&movie.MovieId, &movie.Title, &movie.ReleaseYear, &movie.Genre, &movie.CoverUrl, &movie.GeneratedSummary); err != nil {
		if err == sql.ErrNoRows {
			log.Printf("GetMovieByTitle_DB error: %v", err)
			return Movie{}, fmt.Errorf("No movie found with given movie title")
		}
		return Movie{}, fmt.Errorf("GetMovieByTitle_DB error: %v", err)
	}

	return movie, nil
}

// AddMovie_DB inserts a new movie into the database.
func AddMovie_DB(movie Movie) error {
	log.Print("Inside AddMovie_DB func")

	var err error
	if movie.CoverUrl == nil || *movie.CoverUrl == "" {
		_, err = db.Exec("INSERT INTO movie_details (title, releaseYear, genre) VALUES (?,?,?)", movie.Title, movie.ReleaseYear, movie.Genre)
	} else {
		_, err = db.Exec("INSERT INTO movie_details (title, releaseYear, genre, coverUrl) VALUES (?,?,?,?)", movie.Title, movie.ReleaseYear, movie.Genre, movie.CoverUrl)
	}

	if err != nil {
		return fmt.Errorf("AddMovie_DB error: %v", err)
	}

	return nil
}

// UpdateMovieById_DB updates details of an existing movie.
func UpdateMovieById_DB(movieId string, movie Movie) error {
	log.Print("Inside UpdateMovieById_DB func")

	var err error
	if movie.CoverUrl == nil || *movie.CoverUrl == "" {
		_, err = db.Exec("UPDATE movie_details SET title=?, releaseYear=?, genre=? WHERE movieId = ?", movie.Title, movie.ReleaseYear, movie.Genre, movieId)
	} else {
		_, err = db.Exec("UPDATE movie_details SET title=?, releaseYear=?, genre=?, coverUrl=? WHERE movieId = ?", movie.Title, movie.ReleaseYear, movie.Genre, movie.CoverUrl, movieId)
	}
	if err != nil {
		return fmt.Errorf("UpdateMovieById_DB error: %v", err)
	}

	return nil
}

// DeleteMovieById_DB deletes a movie from the database by its ID.
func DeleteMovieById_DB(movieId string) error {
	log.Print("Inside DeleteMovieById_DB func")

	_, err := db.Exec("DELETE FROM movie_details WHERE movieId = ?", movieId)
	if err != nil {
		return fmt.Errorf("DeleteMovieById_DB error: %v", err)
	}

	return nil
}
