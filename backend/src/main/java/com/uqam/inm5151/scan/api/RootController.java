package com.uqam.inm5151.scan.api;

import com.uqam.inm5151.scan.config.AppProperties;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class RootController {

  private final AppProperties props;

  public RootController(AppProperties props) {
    this.props = props;
  }

  @GetMapping("/")
  public Map<String, String> root() {
    return Map.of("app", props.appName(), "docs", "/docs");
  }
}
