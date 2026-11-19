import { COMPANY, SITE, SITE_URL } from "@/config/site";

export const absoluteUrl = (path: string) =>
  new URL(path.startsWith("/") ? path : `/${path}`, SITE_URL).toString().replace(/\/$/, path === "/" ? "/" : "");

export const pageTitle = (title: string) => (title.startsWith(SITE.name) ? title : `${title} | ${SITE.name}`);

export function ogImagePath(path: string) {
  const slug = path === "/" ? "home" : path.replace(/^\//, "").replace(/\//g, "-");
  return `/og/${slug}.png`;
}

export type Crumb = { name: string; path: string };

export function breadcrumbLd(crumbs: Crumb[]) {
  return {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: crumbs.map((c, i) => ({
      "@type": "ListItem",
      position: i + 1,
      name: c.name,
      item: absoluteUrl(c.path),
    })),
  };
}

export const organizationLd = (id = `${SITE_URL}/#organization`) => ({
  "@context": "https://schema.org",
  "@type": "Organization",
  "@id": id,
  name: "GymWiki",
  url: SITE_URL,
  logo: `${SITE_URL}/logo.png`,
  contactPoint: { "@type": "ContactPoint", contactType: "customer support", email: COMPANY.email, availableLanguage: "nl" },
});
