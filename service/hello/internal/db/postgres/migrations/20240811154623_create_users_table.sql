-- +goose Up
-- +goose StatementBegin
CREATE TABLE users (
    name TEXT PRIMARY KEY,
    count INTEGER DEFAULT(1)
);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE users;
-- +goose StatementEnd
