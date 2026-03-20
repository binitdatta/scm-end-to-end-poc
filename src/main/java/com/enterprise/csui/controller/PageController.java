package com.enterprise.csui.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class PageController {

    @GetMapping("/crm")
    public String crm(Model m)         { m.addAttribute("activePage","crm");          return "pages/crm"; }

    @GetMapping("/vendor")
    public String vendor(Model m)      { m.addAttribute("activePage","vendor");        return "pages/vendor"; }

    @GetMapping("/procurement")
    public String procurement(Model m) { m.addAttribute("activePage","procurement");   return "pages/procurement"; }

    @GetMapping("/wms-inbound")
    public String wmsInbound(Model m)  { m.addAttribute("activePage","wms-inbound");  return "pages/wms-inbound"; }

    @GetMapping("/oms")
    public String oms(Model m)         { m.addAttribute("activePage","oms");           return "pages/oms"; }

    @GetMapping("/wms-outbound")
    public String wmsOutbound(Model m) { m.addAttribute("activePage","wms-outbound"); return "pages/wms-outbound"; }

    @GetMapping("/tms")
    public String tms(Model m)         { m.addAttribute("activePage","tms");           return "pages/tms"; }
}
