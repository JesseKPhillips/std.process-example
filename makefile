all: check reverse talk

check: check.d
	dmd check.d

reverse: reverse.d
	dmd reverse.d

talk: talk.d
	dmd talk.d

run: all
	./talk
