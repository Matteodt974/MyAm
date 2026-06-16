package com.uqam.inm5151.scan.service;

public class GeminiDishAnalysisException extends RuntimeException {

  public GeminiDishAnalysisException(String message) {
    super(message);
  }

  public GeminiDishAnalysisException(String message, Throwable cause) {
    super(message, cause);
  }
}
