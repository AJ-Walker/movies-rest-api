DROP TABLE IF EXISTS movie_details;

CREATE TABLE movie_details (
    movieId INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    releaseYear SMALLINT NOT NULL,
    genre VARCHAR(100) NOT NULL,
    coverUrl VARCHAR(255),
    generatedSummary TEXT
);

INSERT INTO movie_details (title, releaseYear, genre, coverUrl, generatedSummary) VALUES
('Pulp Fiction', 1994, 'Crime, Drama', 'https://movies-app-data.s3.ap-south-1.amazonaws.com/images/01956766-a4a2-77e0-bb6c-4edb920e8013.jpg', NULL),
('The Matrix', 1999, 'Science Fiction, Action', 'https://movies-app-data.s3.ap-south-1.amazonaws.com/images/01956766-a4a2-781b-9b0a-5731875f4a77.jpg', NULL),
('Forrest Gump', 1994, 'Drama, Romance', 'https://movies-app-data.s3.ap-south-1.amazonaws.com/images/01956766-a4a2-7832-8da3-bb885db47334.jpg', NULL),
('The Godfather', 1972, 'Crime, Drama', 'https://movies-app-data.s3.ap-south-1.amazonaws.com/images/01956766-a4a2-7836-bd37-0c1cb0ac1f3d.jpg', NULL),
('Interstellar', 2014, 'Science Fiction, Adventure', 'https://movies-app-data.s3.ap-south-1.amazonaws.com/images/01956766-a4a2-7839-8ed8-f51ccda423a5.jpg', NULL),
('Titanic', 1997, 'Romance, Drama', 'https://movies-app-data.s3.ap-south-1.amazonaws.com/images/01956766-a4a2-783c-87f8-e47b5b90a46d.jpg', NULL),
('Jurassic Park', 1993, 'Science Fiction, Adventure', 'https://movies-app-data.s3.ap-south-1.amazonaws.com/images/01956766-a4a2-783f-bb3d-788a18d9a8a1.jpg', NULL),
('The Lion King', 1994, 'Animation, Adventure', 'https://movies-app-data.s3.ap-south-1.amazonaws.com/images/01956766-a4a2-7842-9b6d-0a737174e934.jpg', NULL),
('Fight Club', 1999, 'Drama, Thriller', 'https://movies-app-data.s3.ap-south-1.amazonaws.com/images/01956766-a4a2-7845-8dac-294bd2ce0f65.jpg', NULL),
('Avatar', 2009, 'Science Fiction, Action', 'https://movies-app-data.s3.ap-south-1.amazonaws.com/images/01956766-a4a2-7849-bc25-038cd80bc822.jpg', NULL),
('The Empire Strikes Back', 1980, 'Science Fiction, Action', 'https://movies-app-data.s3.ap-south-1.amazonaws.com/images/01956766-a4a2-784c-8839-1be816404fd8.jpg', NULL),
('Schindler''s List', 1993, 'Drama, History', 'https://movies-app-data.s3.ap-south-1.amazonaws.com/images/01956766-a4a2-784f-a580-929cbb62f7de.jpg', NULL),
('The Lord of the Rings: The Fellowship of the Ring', 2001, 'Fantasy, Adventure', 'https://movies-app-data.s3.ap-south-1.amazonaws.com/images/01956766-a4a2-7852-885b-b22d32e88a52.jpg', NULL),
('Gladiator', 2000, 'Action, Drama', 'https://movies-app-data.s3.ap-south-1.amazonaws.com/images/01956766-a4a2-7855-8897-54b5c02bb90d.jpg', NULL),
('The Silence of the Lambs', 1991, 'Thriller, Crime', 'https://movies-app-data.s3.ap-south-1.amazonaws.com/images/01956766-a4a2-7858-9295-189f7d4f60c4.jpg', NULL),
('Back to the Future', 1985, 'Science Fiction, Adventure', 'https://movies-app-data.s3.ap-south-1.amazonaws.com/images/01956766-a4a2-785b-8b61-b1f7261420a5.jpg', NULL),
('Parasite', 2019, 'Thriller, Drama', 'https://movies-app-data.s3.ap-south-1.amazonaws.com/images/01956766-a4a2-785e-a134-049657a1a75e.jpg', NULL),
('Mad Max: Fury Road', 2015, 'Action, Science Fiction', 'https://movies-app-data.s3.ap-south-1.amazonaws.com/images/01956766-a4a2-7861-a582-484291c04609.jpg', NULL),
('The Avengers', 2012, 'Action, Superhero', 'https://movies-app-data.s3.ap-south-1.amazonaws.com/images/01956766-a4a2-7864-b664-9b6ad88bf123.jpg', NULL),
('Good Will Hunting', 1997, 'Drama', 'https://movies-app-data.s3.ap-south-1.amazonaws.com/images/01956766-a4a2-7867-acb7-3ffb82a149d5.jpg', NULL);