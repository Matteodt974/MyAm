package com.uqam.inm5151.scan.service;

/** Exception levee quand Gemini ne peut pas identifier la langue source du texte. */
public class UnsupportedLanguageException extends RuntimeException {

  public UnsupportedLanguageException(String message) {
    super(message);
  }
}
