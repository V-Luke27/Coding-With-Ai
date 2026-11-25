// Filters CSV rows, keeping only those with given maximum age
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

constexpr size_t LINE_MAX = 100; // Maximum line length
const char DELIMITER[] = ",";    // CSV delimiter

char *ifile, *ofile;
unsigned filter_age_min;
FILE *istream, *ostream;

const char USAGE[] =
    R"(Filters CSV rows, keeping only those with given minimum age
%s minimum-age [input-file] [output-file]

Example: 
%s 18 input.csv output.csv
%s 18 input.csv (outputs to stdout)
%s 18           (inputs from stdin, outputs to stdout)
)";

void filter_stream(FILE *istream, FILE *ostream) {
  char line[LINE_MAX];
  char *fgets_return;
  char *name, *age_str;
  size_t line_no = 0;

  while ((fgets_return = fgets(line, LINE_MAX, istream))) {
    ++line_no;

    if (*fgets_return != '\n') {
      if (strlen(line) > 1) {
        name = strtok(line, DELIMITER);
        age_str = strtok(nullptr, DELIMITER);

        // Alternative to strtok:
        // sscanf(line, "%*[^,],%d", &age);

        if (!age_str) {
          fprintf(stderr, "Line %zu: Age missing.\n", line_no);
        }
      }
    } else {
      // Error
      fprintf(stderr, "Line %zu: Whole line missing.\n", line_no);
      continue;
    }

    // Age processing
    unsigned age;
    auto recognized_count = sscanf(age_str, "%d", &age);
    if (recognized_count == 1) {
      if (age >= filter_age_min)
        // Forward input line to `ostream`
        fprintf(ostream, "%s, %d\n", name, age);
    } else {
      // Error
      fprintf(stderr, "Line %zu: Age value is not a number.\n", line_no);
    }
  }
}

int main(int argc, char *argv[]) {
  switch (argc) {
  case 4:
    // minimum-age ifile ofile
    ofile = argv[3];
  case 3:
    // minimum-age ifile
    ifile = argv[2];
  case 2:
    // minimum-age
    if (!sscanf(argv[1], "%d", &filter_age_min)) {
      puts("First argument is not an age.");
      exit(EXIT_FAILURE);
    }
    break;
  default:
    printf(USAGE, argv[0], argv[0], argv[0], argv[0]);
    return EXIT_SUCCESS;
  }

  // Input file
  if (ifile) {
    istream = fopen(ifile, "r");

    if (!istream) {
      perror("");
      exit(EXIT_FAILURE);
    }
  } else // No file provided
    istream = stdin;

  // Output file
  if (ofile) {
    ostream = fopen(ofile, "w");

    if (!ostream) {
      perror("");
      exit(EXIT_FAILURE);
    }
  } else
    ostream = stdout;

  filter_stream(istream, ostream);
}
