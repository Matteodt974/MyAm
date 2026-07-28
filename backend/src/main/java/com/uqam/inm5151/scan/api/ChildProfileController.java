package com.uqam.inm5151.scan.api;

import com.uqam.inm5151.scan.dto.ChildProfileRequest;
import com.uqam.inm5151.scan.dto.ChildProfileResponse;
import com.uqam.inm5151.scan.service.ChildProfileService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/parents/{guardianId}/children")
public class ChildProfileController {
  private final ChildProfileService childProfiles;

  public ChildProfileController(ChildProfileService childProfiles) {
    this.childProfiles = childProfiles;
  }

  @GetMapping
  public List<ChildProfileResponse> list(@PathVariable Long guardianId) {

    return childProfiles.list(guardianId);
  }

  @PostMapping
  @ResponseStatus(HttpStatus.CREATED)
  public ChildProfileResponse create(
      @PathVariable Long guardianId, @Valid @RequestBody ChildProfileRequest request) {

    return childProfiles.create(guardianId, request);
  }

  @PutMapping("/{childId}")
  public ChildProfileResponse update(
      @PathVariable Long guardianId,
      @PathVariable Long childId,
      @Valid @RequestBody ChildProfileRequest request) {

    return childProfiles.update(guardianId, childId, request);
  }

  @DeleteMapping("/{childId}")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void delete(@PathVariable Long guardianId, @PathVariable Long childId) {
    childProfiles.delete(guardianId, childId);
  }
}
