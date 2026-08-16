package com.enterprise.scmtraining.controller;

import com.enterprise.scmtraining.model.Lesson;
import com.enterprise.scmtraining.service.CourseCatalogService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

import static org.springframework.http.HttpStatus.NOT_FOUND;

@Controller
public class TrainingController {

    private final CourseCatalogService courseCatalogService;

    @Value("${training.links.github}")
    private String githubUrl;

    @Value("${training.links.erp-dashboard}")
    private String erpDashboardUrl;

    @Value("${training.links.agent-control-tower}")
    private String agentControlTowerUrl;

    public TrainingController(CourseCatalogService courseCatalogService) {
        this.courseCatalogService = courseCatalogService;
    }

    @ModelAttribute("lessons")
    public List<Lesson> lessons() {
        return courseCatalogService.findAll();
    }

    @ModelAttribute
    public void globalLinks(Model model) {
        model.addAttribute("githubUrl", githubUrl);
        model.addAttribute("erpDashboardUrl", erpDashboardUrl);
        model.addAttribute("agentControlTowerUrl", agentControlTowerUrl);
    }

    @GetMapping("/")
    public String home(Model model) {
        model.addAttribute("activePage", "home");
        model.addAttribute("pageTitle", "SCM Agentic AI — Course Home");
        return "pages/home";
    }

    @GetMapping("/purpose")
    public String purpose(Model model) {
        model.addAttribute("activePage", "purpose");
        model.addAttribute("pageTitle", "Purpose");
        return "pages/purpose";
    }

    @GetMapping("/business-case")
    public String businessCase(Model model) {
        model.addAttribute("activePage", "business");
        model.addAttribute("pageTitle", "Business Case");
        return "pages/business-case";
    }

    @GetMapping("/architecture")
    public String architecture(Model model) {
        model.addAttribute("activePage", "architecture");
        model.addAttribute("pageTitle", "Architecture");
        return "pages/architecture";
    }

    @GetMapping("/demo")
    public String demo(Model model) {
        model.addAttribute("activePage", "demo");
        model.addAttribute("pageTitle", "Live POC");
        return "pages/demo";
    }

    @GetMapping("/training")
    public String training(Model model) {
        model.addAttribute("activePage", "training");
        model.addAttribute("pageTitle", "Training Roadmap");
        return "pages/training";
    }

    @GetMapping("/training/{slug}")
    public String lesson(@PathVariable String slug, Model model) {
        Lesson lesson = courseCatalogService.findBySlug(slug)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Unknown lesson: " + slug));

        model.addAttribute("activePage", "training");
        model.addAttribute("pageTitle", lesson.title());
        model.addAttribute("lesson", lesson);
        return "pages/lesson";
    }

    @GetMapping("/run-locally")
    public String runLocally(Model model) {
        model.addAttribute("activePage", "run-locally");
        model.addAttribute("pageTitle", "Run the POC Locally");
        return "pages/run-locally";
    }
}
