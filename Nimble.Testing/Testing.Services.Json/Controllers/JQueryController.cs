using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Testing.Services.Json.Models;

namespace Testing.Services.Json.Controllers
{
    public class JQueryController : Controller
    {
        public ActionResult Index()
        {
            ViewBag.Message = "Modify this template to jump-start your ASP.NET MVC application.";

            return View(new JsonModel());
        }

        public ActionResult Common()
        {
            ViewBag.Message = "Your app description page.";

            return View(new JsonModel());
        }

        public ActionResult Security()
        {
            ViewBag.Message = "Your app description page.";

            return View(new JsonModel());
        }

        public ActionResult Owner()
        {
            ViewBag.Message = "Your app description page.";

            return View(new JsonModel());
        }
    }
}
