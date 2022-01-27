--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.21
-- Dumped by pg_dump version 11.13 (Debian 11.13-1.pgdg90+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: activity_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_codes (
    id integer NOT NULL,
    code character varying,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    remote_id integer,
    tenant_id integer
);


--
-- Name: activity_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_codes_id_seq OWNED BY public.activity_codes.id;


--
-- Name: cargo_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cargo_types (
    id integer NOT NULL,
    remote_id integer,
    maintype character varying(255),
    subtype character varying(255),
    subsubtype character varying(255),
    subsubsubtype character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    enabled boolean DEFAULT false,
    tenant_id integer
);


--
-- Name: cargo_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cargo_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cargo_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cargo_types_id_seq OWNED BY public.cargo_types.id;


--
-- Name: companies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.companies (
    id integer NOT NULL,
    name character varying(255),
    email character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    remote_id integer,
    prefunding_type character varying(255),
    prefunding_percent integer,
    tenant_id integer,
    is_supplier boolean
);


--
-- Name: companies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.companies_id_seq OWNED BY public.companies.id;


--
-- Name: configurations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configurations (
    id integer NOT NULL,
    company_name character varying(255),
    company_address1 character varying(255),
    company_address2 character varying(255),
    bank_name character varying(255),
    bank_address1 character varying(255),
    bank_address2 character varying(255),
    swift_code character varying(255),
    bsb_number character varying(255),
    ac_number character varying(255),
    ac_name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    tenant_id integer
);


--
-- Name: configurations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.configurations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: configurations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.configurations_id_seq OWNED BY public.configurations.id;


--
-- Name: currencies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.currencies (
    id integer NOT NULL,
    name character varying(255),
    code character varying(255),
    symbol character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: currencies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.currencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: currencies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.currencies_id_seq OWNED BY public.currencies.id;


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delayed_jobs (
    id integer NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    handler text NOT NULL,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying(255),
    queue character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.delayed_jobs_id_seq OWNED BY public.delayed_jobs.id;


--
-- Name: delayed_jobs_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delayed_jobs_stats (
    id integer NOT NULL,
    attempt integer NOT NULL,
    entity_id integer NOT NULL,
    entity_name text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    run_at timestamp without time zone,
    started_at timestamp without time zone,
    wait_time integer,
    execution_time integer,
    locked_at timestamp without time zone,
    compled_at timestamp without time zone,
    last_error text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    hostname character varying
);


--
-- Name: delayed_jobs_stats_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.delayed_jobs_stats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_stats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.delayed_jobs_stats_id_seq OWNED BY public.delayed_jobs_stats.id;


--
-- Name: disbursement_revisions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.disbursement_revisions (
    id integer NOT NULL,
    disbursement_id integer,
    data public.hstore,
    fields public.hstore,
    descriptions public.hstore,
    "values" public.hstore,
    values_with_tax public.hstore,
    codes public.hstore,
    tax_exempt boolean DEFAULT false,
    number integer,
    cargo_qty integer DEFAULT 0,
    days_alongside numeric DEFAULT 0.0,
    loadtime integer DEFAULT 0,
    tugs_in integer DEFAULT 0,
    tugs_out integer DEFAULT 0,
    reference character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    cargo_type_id integer,
    comments public.hstore,
    eta date,
    compulsory public.hstore,
    overriden public.hstore,
    disabled public.hstore,
    user_id integer,
    anonymous_views integer DEFAULT 0,
    pdf_views integer DEFAULT 0,
    voyage_number character varying(255),
    amount numeric,
    currency_symbol character varying(255),
    hints public.hstore,
    activity_codes public.hstore,
    tenant_id integer,
    supplier_id public.hstore,
    supplier_name public.hstore
);


--
-- Name: disbursement_revisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.disbursement_revisions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: disbursement_revisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.disbursement_revisions_id_seq OWNED BY public.disbursement_revisions.id;


--
-- Name: disbursements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.disbursements (
    id integer NOT NULL,
    port_id integer,
    vessel_id integer,
    company_id integer,
    status_cd integer DEFAULT 0,
    publication_id character varying(255),
    tbn boolean DEFAULT false,
    grt numeric,
    nrt numeric,
    dwt numeric,
    loa numeric,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    terminal_id integer,
    user_id integer,
    office_id integer,
    current_revision_id integer,
    aos_id integer,
    type_cd integer DEFAULT 0,
    nomination_id integer,
    appointment_id integer,
    nomination_reference character varying(255),
    tenant_id integer,
    sbt_certified boolean
);


--
-- Name: disbursements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.disbursements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: disbursements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.disbursements_id_seq OWNED BY public.disbursements.id;


--
-- Name: estimate_revisions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.estimate_revisions (
    id integer NOT NULL,
    estimate_id integer,
    data public.hstore,
    fields public.hstore,
    descriptions public.hstore,
    "values" public.hstore,
    values_with_tax public.hstore,
    codes public.hstore,
    number integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    cargo_qty integer DEFAULT 0,
    days_alongside integer DEFAULT 0,
    loadtime integer DEFAULT 0,
    tugs_in integer DEFAULT 0,
    tugs_out integer DEFAULT 0
);


--
-- Name: estimate_revisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.estimate_revisions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: estimate_revisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.estimate_revisions_id_seq OWNED BY public.estimate_revisions.id;


--
-- Name: estimates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.estimates (
    id integer NOT NULL,
    port_id integer,
    vessel_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    status_cd integer DEFAULT 0,
    publication_id character varying(255)
);


--
-- Name: estimates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.estimates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: estimates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.estimates_id_seq OWNED BY public.estimates.id;


--
-- Name: offices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.offices (
    id integer NOT NULL,
    name character varying(255),
    address_1 character varying(255),
    address_2 character varying(255),
    address_3 character varying(255),
    phone character varying(255),
    fax character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    email character varying(255),
    remote_id integer,
    tenant_id integer
);


--
-- Name: offices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.offices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: offices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.offices_id_seq OWNED BY public.offices.id;


--
-- Name: offices_ports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.offices_ports (
    id integer NOT NULL,
    office_id integer,
    port_id integer,
    tenant_id integer
);


--
-- Name: offices_ports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.offices_ports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: offices_ports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.offices_ports_id_seq OWNED BY public.offices_ports.id;


--
-- Name: pfda_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pfda_views (
    id integer NOT NULL,
    user_agent text,
    browser character varying(255),
    browser_version character varying(255),
    ip character varying(255),
    pdf boolean,
    disbursement_revision_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    tenant_id integer
);


--
-- Name: pfda_views_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pfda_views_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pfda_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pfda_views_id_seq OWNED BY public.pfda_views.id;


--
-- Name: ports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ports (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    currency_id integer,
    tax_id integer,
    office_id integer,
    services_count integer DEFAULT 0,
    terminals_count integer DEFAULT 0,
    tariffs_count integer DEFAULT 0,
    remote_id integer,
    metadata public.hstore,
    tenant_id integer
);


--
-- Name: ports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ports_id_seq OWNED BY public.ports.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: service_updates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_updates (
    id integer NOT NULL,
    service_id integer,
    user_id integer,
    old_code text,
    new_code text,
    changelog text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    document character varying(255),
    tenant_id integer
);


--
-- Name: service_updates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.service_updates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: service_updates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.service_updates_id_seq OWNED BY public.service_updates.id;


--
-- Name: services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.services (
    id integer NOT NULL,
    port_id integer,
    terminal_id integer,
    code text,
    item character varying(255),
    key character varying(255),
    row_order integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer,
    document character varying(255),
    compulsory boolean DEFAULT true,
    activity_code_id integer,
    tenant_id integer,
    company_id integer,
    disabled boolean DEFAULT false
);


--
-- Name: services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.services_id_seq OWNED BY public.services.id;


--
-- Name: tariffs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tariffs (
    id integer NOT NULL,
    name character varying(255),
    document character varying(255),
    user_id integer,
    port_id integer,
    terminal_id integer,
    validity_start date,
    validity_end date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    tenant_id integer
);


--
-- Name: tariffs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tariffs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tariffs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tariffs_id_seq OWNED BY public.tariffs.id;


--
-- Name: taxes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.taxes (
    id integer NOT NULL,
    name character varying(255),
    rate numeric,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    code character varying(255)
);


--
-- Name: taxes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.taxes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: taxes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.taxes_id_seq OWNED BY public.taxes.id;


--
-- Name: tenants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenants (
    id integer NOT NULL,
    name character varying,
    display character varying,
    full_name character varying,
    aos_name character varying,
    favicon character varying,
    default_email character varying,
    logo character varying,
    terms character varying,
    piwik_id integer,
    aos_api_url character varying,
    aos_api_user character varying,
    aos_api_password character varying,
    aos_api_psk character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tenants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tenants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tenants_id_seq OWNED BY public.tenants.id;


--
-- Name: terminals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.terminals (
    id integer NOT NULL,
    port_id integer,
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    remote_id integer,
    metadata public.hstore,
    tenant_id integer
);


--
-- Name: terminals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.terminals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: terminals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.terminals_id_seq OWNED BY public.terminals.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying(255) DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    uid character varying(255),
    provider character varying(255),
    first_name character varying(255),
    last_name character varying(255),
    admin boolean DEFAULT false,
    office_id integer,
    remote_id integer,
    deleted boolean DEFAULT false,
    rocket_id character varying DEFAULT ''::character varying,
    tenant_id integer,
    auth0_id character varying
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: vessel_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vessel_types (
    id integer NOT NULL,
    remote_id integer,
    vessel_type character varying,
    vessel_subtype character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: vessel_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vessel_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vessel_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vessel_types_id_seq OWNED BY public.vessel_types.id;


--
-- Name: vessels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vessels (
    id integer NOT NULL,
    name character varying(255),
    loa numeric,
    grt numeric,
    nrt numeric,
    dwt numeric,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    remote_id integer,
    imo_code integer,
    maintype character varying,
    subtype character varying,
    tenant_id integer,
    sbt_certified boolean
);


--
-- Name: vessels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vessels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vessels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vessels_id_seq OWNED BY public.vessels.id;


--
-- Name: activity_codes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_codes ALTER COLUMN id SET DEFAULT nextval('public.activity_codes_id_seq'::regclass);


--
-- Name: cargo_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cargo_types ALTER COLUMN id SET DEFAULT nextval('public.cargo_types_id_seq'::regclass);


--
-- Name: companies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companies ALTER COLUMN id SET DEFAULT nextval('public.companies_id_seq'::regclass);


--
-- Name: configurations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configurations ALTER COLUMN id SET DEFAULT nextval('public.configurations_id_seq'::regclass);


--
-- Name: currencies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currencies ALTER COLUMN id SET DEFAULT nextval('public.currencies_id_seq'::regclass);


--
-- Name: delayed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs ALTER COLUMN id SET DEFAULT nextval('public.delayed_jobs_id_seq'::regclass);


--
-- Name: delayed_jobs_stats id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs_stats ALTER COLUMN id SET DEFAULT nextval('public.delayed_jobs_stats_id_seq'::regclass);


--
-- Name: disbursement_revisions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disbursement_revisions ALTER COLUMN id SET DEFAULT nextval('public.disbursement_revisions_id_seq'::regclass);


--
-- Name: disbursements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disbursements ALTER COLUMN id SET DEFAULT nextval('public.disbursements_id_seq'::regclass);


--
-- Name: estimate_revisions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estimate_revisions ALTER COLUMN id SET DEFAULT nextval('public.estimate_revisions_id_seq'::regclass);


--
-- Name: estimates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estimates ALTER COLUMN id SET DEFAULT nextval('public.estimates_id_seq'::regclass);


--
-- Name: offices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offices ALTER COLUMN id SET DEFAULT nextval('public.offices_id_seq'::regclass);


--
-- Name: offices_ports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offices_ports ALTER COLUMN id SET DEFAULT nextval('public.offices_ports_id_seq'::regclass);


--
-- Name: pfda_views id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfda_views ALTER COLUMN id SET DEFAULT nextval('public.pfda_views_id_seq'::regclass);


--
-- Name: ports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ports ALTER COLUMN id SET DEFAULT nextval('public.ports_id_seq'::regclass);


--
-- Name: service_updates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_updates ALTER COLUMN id SET DEFAULT nextval('public.service_updates_id_seq'::regclass);


--
-- Name: services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services ALTER COLUMN id SET DEFAULT nextval('public.services_id_seq'::regclass);


--
-- Name: tariffs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tariffs ALTER COLUMN id SET DEFAULT nextval('public.tariffs_id_seq'::regclass);


--
-- Name: taxes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taxes ALTER COLUMN id SET DEFAULT nextval('public.taxes_id_seq'::regclass);


--
-- Name: tenants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants ALTER COLUMN id SET DEFAULT nextval('public.tenants_id_seq'::regclass);


--
-- Name: terminals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.terminals ALTER COLUMN id SET DEFAULT nextval('public.terminals_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: vessel_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vessel_types ALTER COLUMN id SET DEFAULT nextval('public.vessel_types_id_seq'::regclass);


--
-- Name: vessels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vessels ALTER COLUMN id SET DEFAULT nextval('public.vessels_id_seq'::regclass);


--
-- Name: activity_codes activity_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_codes
    ADD CONSTRAINT activity_codes_pkey PRIMARY KEY (id);


--
-- Name: cargo_types cargo_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cargo_types
    ADD CONSTRAINT cargo_types_pkey PRIMARY KEY (id);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: configurations configurations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configurations
    ADD CONSTRAINT configurations_pkey PRIMARY KEY (id);


--
-- Name: currencies currencies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currencies
    ADD CONSTRAINT currencies_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_stats delayed_jobs_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs_stats
    ADD CONSTRAINT delayed_jobs_stats_pkey PRIMARY KEY (id);


--
-- Name: disbursement_revisions disbursement_revisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disbursement_revisions
    ADD CONSTRAINT disbursement_revisions_pkey PRIMARY KEY (id);


--
-- Name: disbursements disbursements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disbursements
    ADD CONSTRAINT disbursements_pkey PRIMARY KEY (id);


--
-- Name: estimate_revisions estimate_revisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estimate_revisions
    ADD CONSTRAINT estimate_revisions_pkey PRIMARY KEY (id);


--
-- Name: estimates estimates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estimates
    ADD CONSTRAINT estimates_pkey PRIMARY KEY (id);


--
-- Name: offices offices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offices
    ADD CONSTRAINT offices_pkey PRIMARY KEY (id);


--
-- Name: offices_ports offices_ports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offices_ports
    ADD CONSTRAINT offices_ports_pkey PRIMARY KEY (id);


--
-- Name: pfda_views pfda_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfda_views
    ADD CONSTRAINT pfda_views_pkey PRIMARY KEY (id);


--
-- Name: ports ports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ports
    ADD CONSTRAINT ports_pkey PRIMARY KEY (id);


--
-- Name: service_updates service_updates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_updates
    ADD CONSTRAINT service_updates_pkey PRIMARY KEY (id);


--
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- Name: tariffs tariffs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tariffs
    ADD CONSTRAINT tariffs_pkey PRIMARY KEY (id);


--
-- Name: taxes taxes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taxes
    ADD CONSTRAINT taxes_pkey PRIMARY KEY (id);


--
-- Name: tenants tenants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (id);


--
-- Name: terminals terminals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.terminals
    ADD CONSTRAINT terminals_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vessel_types vessel_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vessel_types
    ADD CONSTRAINT vessel_types_pkey PRIMARY KEY (id);


--
-- Name: vessels vessels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vessels
    ADD CONSTRAINT vessels_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX delayed_jobs_priority ON public.delayed_jobs USING btree (priority, run_at);


--
-- Name: index_delayed_jobs_stats_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delayed_jobs_stats_on_created_at ON public.delayed_jobs_stats USING btree (created_at);


--
-- Name: index_delayed_jobs_stats_on_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delayed_jobs_stats_on_entity_id ON public.delayed_jobs_stats USING btree (entity_id);


--
-- Name: index_services_on_activity_code_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_services_on_activity_code_id ON public.services USING btree (activity_code_id);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON public.schema_migrations USING btree (version);


--
-- Name: services fk_rails_e798075302; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT fk_rails_e798075302 FOREIGN KEY (activity_code_id) REFERENCES public.activity_codes(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO schema_migrations (version) VALUES ('20130116125348');

INSERT INTO schema_migrations (version) VALUES ('20130123211947');

INSERT INTO schema_migrations (version) VALUES ('20130123212055');

INSERT INTO schema_migrations (version) VALUES ('20130123212244');

INSERT INTO schema_migrations (version) VALUES ('20130123235549');

INSERT INTO schema_migrations (version) VALUES ('20130124000855');

INSERT INTO schema_migrations (version) VALUES ('20130124005800');

INSERT INTO schema_migrations (version) VALUES ('20130124204511');

INSERT INTO schema_migrations (version) VALUES ('20130125010942');

INSERT INTO schema_migrations (version) VALUES ('20130125011024');

INSERT INTO schema_migrations (version) VALUES ('20130125011126');

INSERT INTO schema_migrations (version) VALUES ('20130125013410');

INSERT INTO schema_migrations (version) VALUES ('20130125123702');

INSERT INTO schema_migrations (version) VALUES ('20130220165332');

INSERT INTO schema_migrations (version) VALUES ('20130221153937');

INSERT INTO schema_migrations (version) VALUES ('20130222091947');

INSERT INTO schema_migrations (version) VALUES ('20130222093256');

INSERT INTO schema_migrations (version) VALUES ('20130222093818');

INSERT INTO schema_migrations (version) VALUES ('20130222094008');

INSERT INTO schema_migrations (version) VALUES ('20130222121420');

INSERT INTO schema_migrations (version) VALUES ('20130301153738');

INSERT INTO schema_migrations (version) VALUES ('20130301153900');

INSERT INTO schema_migrations (version) VALUES ('20130301171034');

INSERT INTO schema_migrations (version) VALUES ('20130312150618');

INSERT INTO schema_migrations (version) VALUES ('20130312151332');

INSERT INTO schema_migrations (version) VALUES ('20130313091336');

INSERT INTO schema_migrations (version) VALUES ('20130313140148');

INSERT INTO schema_migrations (version) VALUES ('20130313140611');

INSERT INTO schema_migrations (version) VALUES ('20130313193707');

INSERT INTO schema_migrations (version) VALUES ('20130405175007');

INSERT INTO schema_migrations (version) VALUES ('20130405175028');

INSERT INTO schema_migrations (version) VALUES ('20130412184133');

INSERT INTO schema_migrations (version) VALUES ('20130416154537');

INSERT INTO schema_migrations (version) VALUES ('20130416161933');

INSERT INTO schema_migrations (version) VALUES ('20130426053551');

INSERT INTO schema_migrations (version) VALUES ('20130503055555');

INSERT INTO schema_migrations (version) VALUES ('20130503060013');

INSERT INTO schema_migrations (version) VALUES ('20130503060144');

INSERT INTO schema_migrations (version) VALUES ('20130503080135');

INSERT INTO schema_migrations (version) VALUES ('20130503080157');

INSERT INTO schema_migrations (version) VALUES ('20130515132211');

INSERT INTO schema_migrations (version) VALUES ('20130515155708');

INSERT INTO schema_migrations (version) VALUES ('20130515160944');

INSERT INTO schema_migrations (version) VALUES ('20130517090244');

INSERT INTO schema_migrations (version) VALUES ('20130531145814');

INSERT INTO schema_migrations (version) VALUES ('20130531151258');

INSERT INTO schema_migrations (version) VALUES ('20130531151903');

INSERT INTO schema_migrations (version) VALUES ('20130705175044');

INSERT INTO schema_migrations (version) VALUES ('20130708054043');

INSERT INTO schema_migrations (version) VALUES ('20130801165242');

INSERT INTO schema_migrations (version) VALUES ('20130823103547');

INSERT INTO schema_migrations (version) VALUES ('20130827065522');

INSERT INTO schema_migrations (version) VALUES ('20130903120110');

INSERT INTO schema_migrations (version) VALUES ('20131030073037');

INSERT INTO schema_migrations (version) VALUES ('20131111084720');

INSERT INTO schema_migrations (version) VALUES ('20140110104908');

INSERT INTO schema_migrations (version) VALUES ('20140110105938');

INSERT INTO schema_migrations (version) VALUES ('20140212021230');

INSERT INTO schema_migrations (version) VALUES ('20140409074222');

INSERT INTO schema_migrations (version) VALUES ('20140429082631');

INSERT INTO schema_migrations (version) VALUES ('20140610094951');

INSERT INTO schema_migrations (version) VALUES ('20140610170112');

INSERT INTO schema_migrations (version) VALUES ('20140610170508');

INSERT INTO schema_migrations (version) VALUES ('20140616144704');

INSERT INTO schema_migrations (version) VALUES ('20140617074721');

INSERT INTO schema_migrations (version) VALUES ('20140617152058');

INSERT INTO schema_migrations (version) VALUES ('20140617152120');

INSERT INTO schema_migrations (version) VALUES ('20140617153800');

INSERT INTO schema_migrations (version) VALUES ('20140618052754');

INSERT INTO schema_migrations (version) VALUES ('20140618052939');

INSERT INTO schema_migrations (version) VALUES ('20140620154312');

INSERT INTO schema_migrations (version) VALUES ('20140620154753');

INSERT INTO schema_migrations (version) VALUES ('20140623131845');

INSERT INTO schema_migrations (version) VALUES ('20140624100705');

INSERT INTO schema_migrations (version) VALUES ('20140722085112');

INSERT INTO schema_migrations (version) VALUES ('20140728084202');

INSERT INTO schema_migrations (version) VALUES ('20141222110933');

INSERT INTO schema_migrations (version) VALUES ('20150128060100');

INSERT INTO schema_migrations (version) VALUES ('20150227103344');

INSERT INTO schema_migrations (version) VALUES ('20150424124210');

INSERT INTO schema_migrations (version) VALUES ('20150424125206');

INSERT INTO schema_migrations (version) VALUES ('20150504100551');

INSERT INTO schema_migrations (version) VALUES ('20150506155442');

INSERT INTO schema_migrations (version) VALUES ('20160624162843');

INSERT INTO schema_migrations (version) VALUES ('20160627133650');

INSERT INTO schema_migrations (version) VALUES ('20160704071405');

INSERT INTO schema_migrations (version) VALUES ('20160704072219');

INSERT INTO schema_migrations (version) VALUES ('20171025180000');

INSERT INTO schema_migrations (version) VALUES ('20171125002900');

INSERT INTO schema_migrations (version) VALUES ('20171201140000');

INSERT INTO schema_migrations (version) VALUES ('20171204110000');

INSERT INTO schema_migrations (version) VALUES ('20171205150000');

INSERT INTO schema_migrations (version) VALUES ('20171222195804');

INSERT INTO schema_migrations (version) VALUES ('20180125113825');

INSERT INTO schema_migrations (version) VALUES ('20180615044550');

INSERT INTO schema_migrations (version) VALUES ('20190910150600');

INSERT INTO schema_migrations (version) VALUES ('20191003143800');

INSERT INTO schema_migrations (version) VALUES ('20200324125348');

INSERT INTO schema_migrations (version) VALUES ('20200324132958');

INSERT INTO schema_migrations (version) VALUES ('20200421095129');

INSERT INTO schema_migrations (version) VALUES ('20200506075210');

INSERT INTO schema_migrations (version) VALUES ('20200511063828');

INSERT INTO schema_migrations (version) VALUES ('20200522090841');

INSERT INTO schema_migrations (version) VALUES ('20200601144904');

INSERT INTO schema_migrations (version) VALUES ('20200619064604');

INSERT INTO schema_migrations (version) VALUES ('20200622130545');

INSERT INTO schema_migrations (version) VALUES ('20200622130604');

INSERT INTO schema_migrations (version) VALUES ('20200709211308');

INSERT INTO schema_migrations (version) VALUES ('20200804091510');

INSERT INTO schema_migrations (version) VALUES ('20200811103703');

INSERT INTO schema_migrations (version) VALUES ('20201001085152');

INSERT INTO schema_migrations (version) VALUES ('20201207122559');

INSERT INTO schema_migrations (version) VALUES ('20210311095245');

INSERT INTO schema_migrations (version) VALUES ('20210330150710');

INSERT INTO schema_migrations (version) VALUES ('20210907083739');

