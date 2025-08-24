package main

// Import necessary packages
import (
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

// Movie represents a single movie record stored in the database.
// Fields map to JSON when returned by the API. Pointer fields allow null values
// when a value is optional or not yet populated (for example, cover image or
// an AI-generated summary).
type Movie struct {
	MovieId          int     `json:"movieId"`
	Title            string  `json:"title"`
	ReleaseYear      uint16  `json:"releaseYear"`
	Genre            string  `json:"genre"`
	CoverUrl         *string `json:"coverUrl"`         // Pointer to allow null values
	GeneratedSummary *string `json:"generatedSummary"` // Pointer to allow null values
}

// main is the program entry point. It configures logging, loads environment
// variables, initializes AWS clients, connects to the database, and registers
// HTTP routes. The function blocks serving HTTP on localhost:8080 until the
// process exits.
func main() {
	// Set log flags (adds timestamp)
	log.SetFlags(log.Ldate | log.Ltime | log.Lshortfile)

	// load environement variables
	if err := godotenv.Load(); err != nil {
		log.Fatalf("Cannot load environment variables. Error occured: %v", err)
	}

	// Initialize AWS clients
	InitAWSClients()

	db_password, err := GetSecretByKey(os.Getenv("SECRET_ARN"), os.Getenv("DB_SECRET_KEY"))
	if err != nil {
		log.Fatalf("%s", err.Error())
	}

	// DB connect and ping
	if err := DBConnectAndPing(db_password); err != nil {
		log.Fatal(err)
	}

	// Initialize router
	router := gin.Default()

	// Set a lower memory limit for multipart forms (default is 32 MiB)
	router.MaxMultipartMemory = 10 << 20 // 10 MiB

	apiGroup := router.Group("/api")
	{
		moviesGroup := apiGroup.Group("/movies")
		{
			moviesGroup.GET("", getMovies)
			moviesGroup.GET("/:movieId", getMovieById)
			moviesGroup.POST("", addMovie)
			moviesGroup.PUT("/:movieId", updateMovie)
			moviesGroup.DELETE("/:movieId", deleteMovie)
			moviesGroup.GET("/:movieId/summary", getMovieSummary)
		}
	}

	// healthcheck route
	router.GET("/healthcheck", healthcheck)

	router.Run("localhost:8080") // listen and serve on localhost:8080
}

// healthcheck responds with a simple liveness response used by load
// balancers and monitoring systems. It returns HTTP 200 with {"status":"ok"}.
func healthcheck(c *gin.Context) {
	log.Print("Inside healthcheck")
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// getMovies handles GET /api/movies. If a "year" query parameter is provided,
// the handler returns movies released in that year. Otherwise it returns all
// movies. The response follows the application's standard response envelope.
func getMovies(c *gin.Context) {
	log.Print("Inside getMovies func")

	log.Printf("Query: year = %v", c.Query("year"))

	var result []Movie
	var err error
	if c.Query("year") == "" {
		result, err = GetAllMovies_DB()
	} else {
		result, err = GetMoviesByYear_DB(c.Query("year"))
	}

	if err != nil {
		log.Print(err)
		c.JSON(http.StatusBadRequest, response(http.StatusBadRequest, false, err.Error(), nil))
		return
	}

	if len(result) == 0 {
		c.JSON(http.StatusNotFound, response(http.StatusNotFound, false, "No movies found", nil))
		return
	}

	c.JSON(http.StatusOK, response(http.StatusOK, true, "Movies fetched successfully.", result))
}

// getMovieSummary handles GET /api/movies/:movieId/summary. It returns an
// AI-generated summary for the requested movie. If no summary exists in the
// database, the handler triggers generation via Bedrock and persists the result.
func getMovieSummary(c *gin.Context) {
	log.Print("Inside getMovieSummary func")

	movieId := c.Param("movieId")
	if movieId == "" {
		c.JSON(http.StatusBadRequest, response(http.StatusBadRequest, false, "MovieId cannot be empty", nil))
		return
	}

	result, err := GetMovieSummary_DB(movieId)
	if err != nil {
		c.JSON(http.StatusBadRequest, response(http.StatusBadRequest, false, err.Error(), nil))
		return
	}

	data := map[string]string{
		"summary": result,
	}

	c.JSON(http.StatusOK, response(http.StatusOK, true, "Movie summary fetched.", data))
}

// getMovieById handles GET /api/movies/:movieId and returns the full movie
// record for the provided movieId. It validates the path parameter and returns
// appropriate HTTP error codes when the movie is not found or on internal errors.
func getMovieById(c *gin.Context) {
	log.Print("Inside getMovieById func")

	movieId := c.Param("movieId")
	if movieId == "" {
		c.JSON(http.StatusBadRequest, response(http.StatusBadRequest, false, "MovieId cannot be empty", nil))
		return
	}

	result, err := GetMovieById_DB(movieId)
	if err != nil {
		c.JSON(http.StatusBadRequest, response(http.StatusBadRequest, false, err.Error(), nil))
		return
	}

	c.JSON(http.StatusOK, response(http.StatusOK, true, "Movie fetched successfully", result))
}

// addMovie handles POST /api/movies. It validates the incoming payload,
// prevents duplicate titles, optionally uploads a cover image to S3, and
// inserts the new movie record into the database. On success it returns the
// created resource or an appropriate error response.
func addMovie(c *gin.Context) {
	log.Print("Inside addMovie func")

	title := c.PostForm("title")
	releaseYear := c.PostForm("releaseYear")
	genre := c.PostForm("genre")

	log.Printf("FormData: title = %v, releaseYear = %v, genre = %v", title, releaseYear, genre)

	if title == "" || releaseYear == "" || genre == "" {
		c.JSON(http.StatusBadRequest, response(http.StatusBadRequest, false, "'title' or 'releaseYear' or 'genre' field cannot be empty", nil))
		return
	}

	// check if movie is being created with same title
	result, _ := GetMovieByTitle_DB(title)

	if strings.TrimSpace(strings.ToLower(result.Title)) == strings.TrimSpace(strings.ToLower(title)) {
		log.Printf("Movie with same title already exists")
		c.JSON(http.StatusBadRequest, response(http.StatusBadRequest, false, "movie with same title already exists", nil))
		return
	}

	var objectUrl string

	coverImage, _ := c.FormFile("coverImage")
	if coverImage != nil {
		log.Printf("Movie coverImage file provided, Filename: %v", coverImage.Filename)

		fileExtension := filepath.Ext(coverImage.Filename)
		uuid, err := generateUUID()
		if err != nil {
			c.JSON(http.StatusBadRequest, response(http.StatusBadRequest, false, "Error generating unique id", nil))
			return
		}

		// upload file to s3
		key := fmt.Sprintf("%v%v", uuid, fileExtension)
		log.Printf("object key: %v", key)

		// var err error
		objectUrl, err = PutObject_S3(coverImage, key)

		if err != nil {
			c.JSON(http.StatusBadRequest, response(http.StatusBadRequest, false, err.Error(), nil))
			return
		}

		log.Printf("Object Url: %v", objectUrl)
	}

	year, err := strconv.Atoi(releaseYear)
	if err != nil {
		c.JSON(http.StatusBadRequest, response(http.StatusBadRequest, false, "Error converting string to int", nil))
		return
	}

	movie := Movie{
		Title:       title,
		ReleaseYear: uint16(year),
		Genre:       genre,
	}

	if objectUrl != "" {
		movie.CoverUrl = &objectUrl
	}

	if err := AddMovie_DB(movie); err != nil {
		c.JSON(http.StatusBadRequest, response(http.StatusBadRequest, false, err.Error(), nil))
		return
	}

	c.JSON(http.StatusOK, response(http.StatusOK, true, "Movie added successfully", nil))
}

// updateMovie handles PUT /api/movies/:movieId. It validates the payload and
// the existence of the target movie, prevents title duplication, optionally
// updates the cover image in S3, and persists updates to the database.
func updateMovie(c *gin.Context) {
	log.Print("Inside updateMovie func")

	movieId := c.Param("movieId")
	if movieId == "" {
		c.JSON(http.StatusBadRequest, response(http.StatusBadRequest, false, "MovieId cannot be empty", nil))
		return
	}

	title := c.PostForm("title")
	releaseYear := c.PostForm("releaseYear")
	genre := c.PostForm("genre")

	log.Printf("FormData: title = %v, releaseYear = %v, genre = %v", title, releaseYear, genre)

	if title == "" || releaseYear == "" || genre == "" {
		c.JSON(http.StatusBadRequest, response(http.StatusBadRequest, false, "'title' or 'releaseYear' or 'genre' field cannot be empty", nil))
		return
	}

	// Check if movie exists with the provided movieId
	movie, err := GetMovieById_DB(movieId)
	if err != nil {
		c.JSON(http.StatusBadRequest, response(http.StatusBadRequest, false, err.Error(), nil))
		return
	}

	log.Print(movie)

	if strings.TrimSpace(strings.ToLower(movie.Title)) != strings.TrimSpace(strings.ToLower(title)) {
		// Check if movie is being created with same title
		result, _ := GetMovieByTitle_DB(title)

		if strings.TrimSpace(strings.ToLower(result.Title)) == strings.TrimSpace(strings.ToLower(title)) {
			log.Printf("Movie with same title already exists")
			c.JSON(http.StatusBadRequest, response(http.StatusBadRequest, false, "movie with same title already exists", nil))
			return
		}
	}

	var objectUrl string

	coverImage, _ := c.FormFile("coverImage")
	if coverImage != nil {
		log.Printf("Movie coverImage file provided, Filename: %v", coverImage.Filename)

		fileExtension := filepath.Ext(coverImage.Filename)
		uuid, err := generateUUID()
		if err != nil {
			c.JSON(http.StatusBadRequest, response(http.StatusBadRequest, false, "Error generating unique id", nil))
			return
		}

		// Upload file to s3
		key := fmt.Sprintf("%v%v", uuid, fileExtension)
		log.Printf("object key: %v", key)

		// var err error
		objectUrl, err = PutObject_S3(coverImage, key)

		if err != nil {
			c.JSON(http.StatusBadRequest, response(http.StatusBadRequest, false, err.Error(), nil))
			return
		}

		log.Printf("Object Url: %v", objectUrl)
	}

	year, err := strconv.Atoi(releaseYear)
	if err != nil {
		c.JSON(http.StatusBadRequest, response(http.StatusBadRequest, false, "Error converting string to int", nil))
		return
	}

	movie = Movie{
		Title:       title,
		ReleaseYear: uint16(year),
		Genre:       genre,
	}

	if objectUrl != "" {
		movie.CoverUrl = &objectUrl
	}

	if err := UpdateMovieById_DB(movieId, movie); err != nil {
		c.JSON(http.StatusBadRequest, response(http.StatusBadRequest, false, err.Error(), nil))
		return
	}

	c.JSON(http.StatusOK, response(http.StatusOK, true, "Movie updated successfully", nil))
}

// deleteMovie handles DELETE /api/movies/:movieId. It removes the movie
// record from the database and deletes any associated cover image from S3.
// The handler validates that the movie exists before performing the delete.
func deleteMovie(c *gin.Context) {
	log.Print("Inside deleteMovie func")

	movieId := c.Param("movieId")
	if movieId == "" {
		c.JSON(http.StatusBadRequest, response(http.StatusBadRequest, false, "MovieId cannot be empty", nil))
		return
	}

	// Check if movie exists with the provided movieId
	movie, err := GetMovieById_DB(movieId)
	if err != nil {
		c.JSON(http.StatusBadRequest, response(http.StatusBadRequest, false, err.Error(), nil))
		return
	}

	if err := DeleteMovieById_DB(movieId); err != nil {
		c.JSON(http.StatusBadRequest, response(http.StatusBadRequest, false, err.Error(), nil))
		return
	}

	if movie.CoverUrl != nil || *movie.CoverUrl != "" {
		splittedString := strings.Split(*movie.CoverUrl, "/")

		objectKey := splittedString[len(splittedString)-1]
		log.Printf("ObjectKey: %v", objectKey)
		if err := DeleteObject_S3(objectKey); err != nil {
			log.Printf("Error while deleting object: %v", err)
		}
	}

	c.JSON(http.StatusOK, response(http.StatusOK, true, "Movie deleted successfully", nil))
}
