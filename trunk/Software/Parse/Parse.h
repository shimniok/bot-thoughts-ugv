/** Useful char / string parsing utilities
 *
 */
class Parse {

public:

  /** convert a single char to an integer
   *
   * @param c is the char to convert
   * @param returns the integer represented by the char
   */
  int ctoi(char c);


  /** convert a char array to floating point
   *
   * @param s is the string to parse
   *
   * @param returns the string as a floating point
   */
  float cvstof(char *s);

  /** copy t to s until delimiter is reached, similar to strtok()
   *
   * @param s is the destination string into which the next token will be copied
   * @param t is the source string out of which we are copying the next token
   * @param delim is the delimiter
   *
   * @param returns location of delimiter+1 in t
   */
  char *split(char *s, char *t, int max, char delim);

};

